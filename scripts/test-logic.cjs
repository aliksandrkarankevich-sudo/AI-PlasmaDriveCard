// Exercise the actual JavaScript functions embedded in QML, not copies.
// This is not a QML engine, layout test, or Plasma integration test.
// Run: node --test scripts/test-logic.cjs (Node.js 18+).
const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const root = process.env.DRIVECARD_SOURCE_ROOT || path.join(__dirname, "..");
const main = fs.readFileSync(path.join(root, "package/contents/ui/main.qml"), "utf8");
const config = fs.readFileSync(path.join(root, "package/contents/ui/ConfigGeneral.qml"), "utf8");
const xml = fs.readFileSync(path.join(root, "package/contents/config/main.xml"), "utf8");

function extract(source, name) {
    const match = new RegExp(`^\\s*function ${name}\\(`, "m").exec(source);
    assert.ok(match, `QML function ${name} exists`);
    const start = source.indexOf("function", match.index);
    // Compile successive candidates so braces in comments/strings are harmless.
    for (let end = source.indexOf("}", start); end >= 0; end = source.indexOf("}", end + 1)) {
        const candidate = `(${source.slice(start, end + 1)})`;
        try { new vm.Script(candidate); return candidate; } catch {}
    }
    throw new Error(`Cannot extract ${name}`);
}

function model() {
    return {
        rows: [], writes: 0, clears: 0,
        get count() { return this.rows.length; },
        get(i) { return this.rows[i]; },
        append(row) { this.rows.push({ ...row }); },
        clear() { this.rows = []; this.clears++; },
        setProperty(i, key, value) { this.rows[i][key] = value; this.writes++; }
    };
}

function runtime(source = main, extras = {}) {
    const context = vm.createContext({
        console, ru: false, previousIo: {}, overrides: {}, storageSnapshot: "",
        drives: model(), scanFailed: false,
        Plasmoid: { configuration: { showRoot: true, showBoot: false, iconStyle: "drive" } },
        Qt: { locale: () => ({ toString: (n, format, digits) => n.toFixed(digits) }) },
        ...extras
    });
    context.root = context;
    for (const match of source.matchAll(/^    ?function (\w+)\(/gm)) {
        context[match[1]] = vm.runInContext(extract(source, match[1]), context);
    }
    if (source === main) {
        const keys = main.match(/readonly property var syncKeys:\s*(\[[\s\S]*?\])/);
        context.syncKeys = vm.runInContext(keys[1], context);
    }
    return context;
}

function scan(filesystems, blockdevices) {
    return JSON.stringify({ filesystems }) + "\n__DC_LSBLK__\n" + JSON.stringify({ blockdevices });
}
const disk = {
    name: "sda", kname: "sda", type: "disk", tran: "sata", rota: false,
    size: 100000, model: "Example SSD",
    children: [{ name: "sda1", kname: "sda1", type: "part" }]
};
const volume = {
    source: "/dev/sda1", target: "/", fstype: "ext4",
    size: 100000, avail: 80000, "use%": "20%"
};
const stats = reads => `8 1 sda1 ${reads} 0 0 0 20 0 0 0 0 0 0\n`;

test("all configuration entries have matching cfg properties and defaults", () => {
    const entries = [...xml.matchAll(/<entry name="(\w+)"\s+type="(\w+)">\s*<default>(.*?)<\/default><\/entry>/g)];
    assert.equal(entries.length, 32);
    for (const [, name, type, value] of entries) {
        assert.match(config, new RegExp(`property\\s+\\w+\\s+cfg_${name}\\s*(?:\\n|:)`));
        const match = config.match(new RegExp(`property\\s+\\w+\\s+cfg_${name}Default:\\s*([^\\n]+)`));
        assert.ok(match, name);
        const expected = type === "Bool" ? value === "true" : type === "Int" ? Number(value) : value;
        assert.equal(vm.runInNewContext(match[1]), expected, name);
    }
});
test("scan creates disk header and volume", () => {
    const c = runtime();
    c.rebuild(scan([volume], [disk]));
    assert.equal(c.scanFailed, false);
    assert.equal(c.rowCount, 1);
    assert.equal(c.groupCount, 1);
    assert.equal(c.drives.rows[0].title, "Example SSD");
    assert.equal(c.drives.rows[1].used, 20);
    assert.equal(c.drives.rows[1].kname, "sda1");
});
test("unchanged scan does not rebuild or rewrite the model", () => {
    const c = runtime(), output = scan([volume], [disk]);
    c.rebuild(output);
    const clears = c.drives.clears;
    c.rebuild(output);
    assert.equal(c.drives.clears, clears);
    assert.equal(c.drives.writes, 0);
});
test("usage changes update only changed roles", () => {
    const c = runtime();
    c.rebuild(scan([volume], [disk]));
    c.rebuild(scan([{ ...volume, avail: 70000, "use%": "30%" }], [disk]));
    assert.equal(c.drives.writes, 2);
    assert.equal(c.drives.rows[1].used, 30);
});
test("malformed scan preserves existing rows", () => {
    const c = runtime();
    c.rebuild(scan([volume], [disk]));
    c.rebuild("bad output");
    assert.equal(c.scanFailed, true);
    assert.equal(c.drives.count, 2);
});
test("root and boot visibility filters", () => {
    const c = runtime();
    c.Plasmoid.configuration.showRoot = false;
    c.rebuild(scan([volume, { ...volume, target: "/boot" }], [disk]));
    assert.equal(c.rowCount, 0);
});
test("Btrfs subvolume sources are deduplicated", () => {
    const c = runtime();
    c.rebuild(scan([
        { ...volume, source: "/dev/sda1[/@]" },
        { ...volume, source: "/dev/sda1[/@home]", target: "/home" }
    ], [disk]));
    assert.equal(c.rowCount, 1);
});
test("USB disks share one group with separate device count", () => {
    const c = runtime();
    c.rebuild(scan([volume, { ...volume, source: "/dev/sdb1", target: "/media/usb" }], [
        { ...disk, tran: "usb" },
        { ...disk, name: "sdb", tran: "usb", children: [{ name: "sdb1", kname: "sdb1", type: "part" }] }
    ]));
    assert.equal(c.groupCount, 1);
    assert.equal(c.drives.rows[0].groupSub, "Devices: 2");
});
test("activity first sample is a baseline, unchanged flags are not written", () => {
    const c = runtime();
    c.drives.append({ isHeader: false, kname: "sda1", active: false });
    c.applyActivity(stats(10));
    assert.equal(c.drives.writes, 0);
    c.applyActivity(stats(11));
    assert.equal(c.drives.rows[0].active, true);
    c.applyActivity(stats(12));
    assert.equal(c.drives.writes, 1);
    c.applyActivity(stats(12));
    assert.equal(c.drives.rows[0].active, false);
    assert.equal(c.drives.writes, 2);
});
test("activity toggle resets stale indicators and baseline", () => {
    const c = runtime();
    c.drives.append({ isHeader: false, kname: "sda1", active: true });
    c.previousIo = { sda1: "1:2" };
    c.resetActivity();
    assert.equal(c.drives.rows[0].active, false);
    assert.equal(Object.keys(c.previousIo).length, 0);
    c.applyActivity(stats(100));
    assert.equal(c.drives.rows[0].active, false);
});
test("hotplug detects changed contents even with identical line counts", () => {
    const c = runtime();
    let refreshes = 0;
    c.scheduleStorageRefresh = () => refreshes++;
    c.updateStorageSnapshot("sda\n/mnt/old\n");
    c.updateStorageSnapshot("sda\n/mnt/old\n");
    assert.equal(refreshes, 0);
    c.updateStorageSnapshot("sdb\n/mnt/new\n");
    assert.equal(refreshes, 1);
    c.updateStorageSnapshot("");
    assert.equal(c.storageSnapshot, "sdb\n/mnt/new\n");
});
test("icon overrides clamp size and encode file paths", () => {
    const c = runtime();
    c.overrides = { "/": { icon: "/tmp/a #.svg", size: 999 } };
    assert.equal(c.iconScaleFor("/"), 300);
    assert.equal(c.displayIcon("/", "ssd"), "file:///tmp/a%20%23.svg");
    assert.equal(c.iconScaleFor("/missing"), 100);
});
test("invalid profile JSON shapes are safely ignored", () => {
    const c = runtime(config, { _factoryId: "__default__" });
    for (const value of ["null", "{}", "42", '"text"', "{bad"]) {
        c.cfg_profiles = value;
        assert.equal(c._loadProfiles().length, 0, value);
    }
});
test("profile list filters malformed entries without dropping valid profiles", () => {
    const c = runtime(config, { _factoryId: "__default__",
        cfg_profiles: '[null, {}, [], {"name":42}, {"name":"default"}, {"name":"Mine","textScale":110}]' });
    const profiles = c._loadProfiles();
    assert.equal(profiles.length, 1);
    assert.equal(profiles[0].name, "Mine");
    assert.equal(profiles[0].textScale, 110);
});
test("malformed override entry does not crash settings summary", () => {
    const c = runtime(config, { cfg_volumeOverrides: '{"/home":null}' });
    assert.equal(c._ovSummary(), "/home");
});
test("visual geometry changes no longer invoke disk scans", () => {
    for (const name of ["TextScale", "RowPaddingV", "SeparatorHeight", "ProgressHeight", "MaxHeight"]) {
        assert.doesNotMatch(main, new RegExp(`on${name}Changed\\(\\).*scheduleStorageRefresh`));
    }
});
