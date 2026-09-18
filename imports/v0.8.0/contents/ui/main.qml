import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
 id: root
 readonly property bool ru: Plasmoid.configuration.language !== "en"
 readonly property int pad: Plasmoid.configuration.contentPadding
 readonly property int rowH: Plasmoid.configuration.rowHeight
 readonly property int wantedHeight: Math.min(Plasmoid.configuration.maxHeight, Math.max(220,pad*2+38+drives.count*rowH))
 property bool scanRunning:false; property bool watchersRunning:false
 function tr2(r,e){return ru?r:e}
 function basename(p){p=(p||"").replace(/\/$/,""); return decodeURIComponent(p.substring(p.lastIndexOf("/")+1))||p}
 function clean(s){return (s||"").replace(/\[.*\]$/,"")}
 function prettyFs(s){s=(s||"").toLowerCase(); if(s==="btrfs")return "Btrfs"; if(s==="vfat")return "FAT"; if(s==="exfat")return "exFAT"; return s.toUpperCase()}
 function formatBytes(n){n=Number(n)||0; const u=ru?["Б","КиБ","МиБ","ГиБ","ТиБ"]:["B","KiB","MiB","GiB","TiB"]; let i=0; while(n>=1024&&i<u.length-1){n/=1024;++i} return Qt.locale(ru?"ru_RU":"en_US").toString(n,"f",i<3?0:1)+" "+u[i]}
 function shortDrive(source,map){let k=clean(source);let n=map[k]||map[basename(k)],g=0;while(n&&n.type!=="disk"&&n.pkname&&g++<12)n=map[n.pkname]||map["/dev/"+n.pkname];if(!n)return "";let name=n.name||basename(n.path||""),t=(n.tran||"").toLowerCase(),m=/^nvme(\d+)n\d+$/.exec(name);if(m)return "NVMe "+m[1];if(t==="usb")return "USB "+name;if(t==="sata"||/^sd[a-z]+$/.test(name))return "SATA "+name;return t?t.toUpperCase()+" "+name:tr2("Диск ","Disk ")+name}
 function flatten(a,o){for(let i=0;i<(a||[]).length;++i){o.push(a[i]);if(a[i].children)flatten(a[i].children,o)}}
 function rebuild(out){const mark="__DC_LSBLK__",at=out.indexOf(mark);if(at<0)return;let fm,lb;try{fm=JSON.parse(out.substring(0,at).trim());lb=JSON.parse(out.substring(at+mark.length).trim())}catch(e){console.warn("DriveCard JSON",e);return}const map=({}),bs=lb.blockdevices||[];for(let i=0;i<bs.length;++i){let b=bs[i];map[b.name]=b;if(b.path)map[b.path]=b;map["/dev/"+b.name]=b;map["/dev/mapper/"+b.name]=b}const all=[],rows=[],seen=({});flatten(fm.filesystems||[],all);for(let i=0;i<all.length;++i){let f=all[i],target=f.target||"",source=clean(f.source);if(!target||source.indexOf("/dev/")!==0)continue;if(!Plasmoid.configuration.showRoot&&target==="/")continue;if(!Plasmoid.configuration.showBoot&&(target==="/boot"||target==="/boot/efi"))continue;if(target.indexOf("/run/snapd/")===0)continue;if(seen[source])continue;let size=Number(f.size)||0,avail=Number(f.avail)||0,used=parseInt(String(f["use%"]||"0"))||0,label=f.label||"";if(target==="/")label=tr2("Система","System");else if(!label)label=basename(target);let physical=shortDrive(source,map);rows.push({title:label,target:target,source:source,fs:prettyFs(f.fstype),physical:physical,total:size,available:avail,used:used,icon:target==="/"?"drive-harddisk-root":(physical.indexOf("USB ")===0?"drive-removable-media-usb":"drive-harddisk")});seen[source]=true}rows.sort(function(a,b){if(a.target==="/")return -1;if(b.target==="/")return 1;return a.title.localeCompare(b.title)});drives.clear();for(let j=0;j<rows.length;++j)drives.append(rows[j]);fitTimer.restart()}
 function refresh(delay){if(delay>0){delayed.interval=delay;delayed.restart();return}if(scanRunning)return;scanRunning=true;exec.connectSource(scanCommand)}
 function stopWatchers(){exec.disconnectSource(mountWatch);exec.disconnectSource(udevWatch);watchersRunning=false}
 function startWatchers(){if(watchersRunning)return;watchersRunning=true;exec.connectSource(mountWatch);exec.connectSource(udevWatch)}
 function storageEvent(){stopWatchers();refresh(1200);restartWatch.restart()}
 function openPath(p){Qt.openUrlExternally("file://"+encodeURI(p))}
 readonly property string scanCommand:"/bin/sh -c 'LC_ALL=C findmnt --json --real --bytes -o SOURCE,TARGET,FSTYPE,LABEL,SIZE,AVAIL,USE%; printf \\"\\n__DC_LSBLK__\\n\\"; LC_ALL=C lsblk --json --bytes -l -o NAME,PATH,PKNAME,TYPE,TRAN,MODEL'"
 readonly property string mountWatch:"/usr/bin/findmnt --poll=mount,umount,move,remount --first-only --output ACTION,TARGET"
 readonly property string udevWatch:"/bin/sh -c 'LC_ALL=C stdbuf -oL udevadm monitor --udev --subsystem-match=block --property 2>/dev/null | grep -m1 -E \\"^ACTION=(add|remove|change)$\\"'"
 Plasmoid.backgroundHints:PlasmaCore.Types.NoBackground
 Plasmoid.preferredRepresentation:Plasmoid.fullRepresentation
 Layout.minimumWidth:360;Layout.preferredWidth:470
 Layout.minimumHeight:Plasmoid.configuration.autoFit?wantedHeight:220
 Layout.preferredHeight:Plasmoid.configuration.autoFit?wantedHeight:420
 Layout.maximumHeight:Plasmoid.configuration.autoFit?wantedHeight:16777215
 ListModel{id:drives}
 Plasma5Support.DataSource{id:exec;engine:"executable";onNewData:function(s,d){if(s===root.scanCommand){disconnectSource(s);root.scanRunning=false;let o=d["stdout"]||"";if(o.length)root.rebuild(o)}else if(s===root.mountWatch||s===root.udevWatch)root.storageEvent()}}
 Timer{id:delayed;repeat:false;onTriggered:root.refresh(0)}
 Timer{id:restartWatch;interval:1800;repeat:false;onTriggered:root.startWatchers()}
 Timer{interval:Math.max(15,Plasmoid.configuration.updateInterval)*1000;repeat:true;running:true;onTriggered:root.refresh(0)}
 Timer{id:fitTimer;interval:150;repeat:false;onTriggered:{if(!Plasmoid.configuration.autoFit)return;root.Layout.minimumHeight=root.wantedHeight;root.Layout.preferredHeight=root.wantedHeight;root.Layout.maximumHeight=root.wantedHeight;root.height=root.wantedHeight}}
 Connections{target:Plasmoid.configuration;function onShowRootChanged(){root.refresh(0)}function onShowBootChanged(){root.refresh(0)}function onRowHeightChanged(){fitTimer.restart()}function onMaxHeightChanged(){fitTimer.restart()}function onAutoFitChanged(){fitTimer.restart()}}
 Component.onCompleted:{refresh(0);startWatchers()}
 Component.onDestruction:stopWatchers()
 fullRepresentation:Item{
  id:view;implicitWidth:470;implicitHeight:root.wantedHeight
  Layout.minimumWidth:360;Layout.preferredWidth:470
  Layout.minimumHeight:Plasmoid.configuration.autoFit?root.wantedHeight:220
  Layout.preferredHeight:Plasmoid.configuration.autoFit?root.wantedHeight:420
  Layout.maximumHeight:Plasmoid.configuration.autoFit?root.wantedHeight:16777215
  readonly property real curve:Math.max(-1,Math.min(1,Plasmoid.configuration.edgeCurve/100))
  readonly property real mainWeight:1-Math.abs(curve)*0.62
  readonly property real narrowWeight:Math.max(0,curve)*0.62
  readonly property real wideWeight:Math.max(0,-curve)*0.62
  readonly property real alpha:Plasmoid.configuration.backgroundOpacity/100
  readonly property real edgeKeep:1-Plasmoid.configuration.edgeOpacity/100
  readonly property int fade:Math.max(0,Plasmoid.configuration.edgeWidth)
  Item{anchors.fill:parent;clip:true
   Rectangle{id:bg;x:view.fade;y:view.fade;width:Math.max(1,parent.width-view.fade*2);height:Math.max(1,parent.height-view.fade*2);radius:Plasmoid.configuration.rounded?Math.max(0,Plasmoid.configuration.cornerRadius-view.fade/3):0;color:Qt.rgba(Kirigami.Theme.backgroundColor.r,Kirigami.Theme.backgroundColor.g,Kirigami.Theme.backgroundColor.b,view.alpha);visible:false;layer.enabled:true}
   MultiEffect{anchors.fill:bg;source:bg;visible:view.mainWeight>.001;opacity:view.mainWeight;blurEnabled:view.fade>0;blur:view.fade>0?1:0;blurMax:Math.max(1,view.fade);paddingRect:Qt.rect(-view.fade,-view.fade,view.fade*2,view.fade*2)}
   MultiEffect{anchors.fill:bg;source:bg;visible:view.narrowWeight>.001;opacity:view.narrowWeight;blurEnabled:view.fade>0;blur:view.fade>0?1:0;blurMax:Math.max(1,Math.round(view.fade*.5));paddingRect:Qt.rect(-view.fade,-view.fade,view.fade*2,view.fade*2)}
   MultiEffect{anchors.fill:bg;source:bg;visible:view.wideWeight>.001;opacity:view.wideWeight;blurEnabled:view.fade>0;blur:view.fade>0?1:0;blurMax:Math.max(1,Math.round(view.fade*1.8));paddingRect:Qt.rect(-view.fade,-view.fade,view.fade*2,view.fade*2)}
   Rectangle{anchors.fill:parent;radius:Plasmoid.configuration.rounded?Plasmoid.configuration.cornerRadius:0;color:Qt.rgba(Kirigami.Theme.backgroundColor.r,Kirigami.Theme.backgroundColor.g,Kirigami.Theme.backgroundColor.b,view.alpha*view.edgeKeep)}
  }
  ColumnLayout{anchors.fill:parent;anchors.margins:root.pad;spacing:4;opacity:Plasmoid.configuration.textOpacity/100
   RowLayout{Layout.fillWidth:true;Layout.preferredHeight:30;spacing:6
    Kirigami.Icon{source:"drive-harddisk";Layout.preferredWidth:22;Layout.preferredHeight:22}
    PC3.Label{text:root.tr2("Диски","Drives");font.bold:true;font.pixelSize:20;Layout.fillWidth:true}
    PC3.Label{text:drives.count;opacity:.72}
   }
   ListView{id:list;Layout.fillWidth:true;Layout.fillHeight:true;clip:true;model:drives;boundsBehavior:Flickable.StopAtBounds
    QQC2.ScrollBar.vertical:QQC2.ScrollBar{policy:list.contentHeight>list.height?QQC2.ScrollBar.AsNeeded:QQC2.ScrollBar.AlwaysOff}
    delegate:Item{
     required property string title;required property string target;required property string source;required property string fs;required property string physical;required property double total;required property double available;required property int used;required property string icon
     width:list.width-(list.contentHeight>list.height?10:0);height:root.rowH
     HoverHandler{id:hover} TapHandler{onTapped:root.openPath(target)}
     QQC2.ToolTip.visible:hover.hovered;QQC2.ToolTip.text:source+"\n"+target
     RowLayout{anchors.fill:parent;anchors.leftMargin:4;anchors.rightMargin:8;spacing:14
      Kirigami.Icon{source:icon;Layout.preferredWidth:Math.min(64,root.rowH-30);Layout.preferredHeight:Layout.preferredWidth}
      ColumnLayout{Layout.fillWidth:true;Layout.alignment:Qt.AlignVCenter;spacing:4
       PC3.Label{text:title;font.bold:true;font.pixelSize:18;elide:Text.ElideRight;Layout.fillWidth:true}
       PC3.Label{text:root.formatBytes(available)+" "+root.tr2("свободно из","free of")+" "+root.formatBytes(total);font.pixelSize:16;elide:Text.ElideRight;Layout.fillWidth:true}
       PC3.Label{visible:Plasmoid.configuration.showFs||Plasmoid.configuration.showPhysical;text:{let a=Plasmoid.configuration.showFs?fs:"",b=Plasmoid.configuration.showPhysical?physical:"";return a&&b?a+"  •  "+b:a+b};opacity:.72;font.pixelSize:13;elide:Text.ElideRight;Layout.fillWidth:true}
       QQC2.ProgressBar{Layout.fillWidth:true;from:0;to:100;value:used;palette.highlight:used>=Plasmoid.configuration.criticalPercent?Kirigami.Theme.negativeTextColor:used>=Plasmoid.configuration.warningPercent?Kirigami.Theme.neutralTextColor:Kirigami.Theme.highlightColor}
       PC3.Label{Layout.alignment:Qt.AlignRight;text:used+"% "+root.tr2("занято","used");font.pixelSize:13}
      }
     }
    }
    PC3.Label{anchors.centerIn:parent;visible:drives.count===0;text:root.scanRunning?root.tr2("Обновление…","Refreshing…"):root.tr2("Доступные диски не найдены","No accessible drives found");opacity:.75}
   }
  }
 }
}
