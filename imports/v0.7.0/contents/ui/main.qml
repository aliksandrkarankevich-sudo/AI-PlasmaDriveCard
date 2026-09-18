import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
 id: root
 property string state: "loading"
 property string errorText: ""
 property bool requestRunning: false
 property bool requestPending: false
 property var blockMap: ({})
 readonly property bool ru: Plasmoid.configuration.language === "ru"
 readonly property real textAlpha: Math.max(0.1,Math.min(1,Plasmoid.configuration.textOpacity/100))
 readonly property int rowH: Math.max(80,Plasmoid.configuration.rowHeight)
 readonly property int headerH: 38
 readonly property int pad: Kirigami.Units.largeSpacing
 readonly property int naturalH: headerH+disks.count*rowH+pad*2
 readonly property int fittedH: Math.max(160,Math.min(naturalH,Math.max(240,Plasmoid.configuration.maxAutoHeight)))
 readonly property int wantedH: Plasmoid.configuration.autoSize?fittedH:300

 Plasmoid.title: ru?"Диски":"Disks"
 Plasmoid.icon: "drive-harddisk"
 Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
 preferredRepresentation: fullRepresentation
 implicitWidth: 400
 implicitHeight: wantedH
 Layout.minimumWidth: 320
 Layout.preferredWidth: 400
 Layout.minimumHeight: Plasmoid.configuration.autoSize?wantedH:160
 Layout.preferredHeight: wantedH
 Layout.maximumHeight: Plasmoid.configuration.autoSize?wantedH:Number.POSITIVE_INFINITY

 ListModel { id: disks }

 function t(r,e){return ru?r:e}
 function bytes(n){var u=ru?["Б","КиБ","МиБ","ГиБ","ТиБ"]:["B","KiB","MiB","GiB","TiB"],v=Number(n),i=0;while(v>=1024&&i<u.length-1){v/=1024;i++}return Qt.locale(ru?"ru_RU":"en_US").toString(v,"f",i>=3?1:0)+" "+u[i]}
 function nameOf(x){if(x.label&&String(x.label).trim())return String(x.label);if(x.target==="/")return t("Система","System");var a=String(x.target).split("/");return a[a.length-1]||String(x.source)}
 function iconOf(x){var l=String(x.label||"").toLowerCase();if(l.indexOf("game")>=0)return "folder-games";if(x.target==="/")return "drive-harddisk-root";if(String(x.fstype).match(/nfs|cifs|smb/))return "folder-network";return "drive-harddisk"}
 function urlOf(p){return "file://"+String(p).split("/").map(encodeURIComponent).join("/")}
 function cleanSource(s){return String(s||"").replace(/\[.*\]$/,"")}
 function baseName(s){var a=cleanSource(s).split("/");return a[a.length-1]}
 function allowed(x){var p=String(x.target||"");if(!p||p[0]!=="/")return false;if(!Plasmoid.configuration.showRoot&&p==="/")return false;if(!Plasmoid.configuration.showBoot&&(p==="/boot"||p.indexOf("/boot/")===0))return false;return Number(x.size||0)>0}
 function fsName(s){var x=String(s||"").toLowerCase();var m={"btrfs":"Btrfs","ext4":"EXT4","ext3":"EXT3","ext2":"EXT2","xfs":"XFS","f2fs":"F2FS","vfat":"FAT","exfat":"exFAT","ntfs3":"NTFS","ntfs":"NTFS","zfs":"ZFS","nfs":"NFS","nfs4":"NFS","cifs":"SMB","fuseblk":"FUSE"};return m[x]||String(s||"").toUpperCase()}
 function inferredDisk(name){var n=String(name||"");var m=n.match(/^(nvme\d+)n\d+(?:p\d+)?$/);if(m)return {name:m[1]+"n1",kname:m[1]+"n1",type:"disk",tran:"nvme",model:""};m=n.match(/^(mmcblk\d+)(?:p\d+)?$/);if(m)return {name:m[1],kname:m[1],type:"disk",tran:"mmc",model:""};m=n.match(/^([shv]d[a-z]+)\d+$/);if(m)return {name:m[1],kname:m[1],type:"disk",tran:"",model:""};return null}
 function diskObject(source){var n=baseName(source),d=blockMap[n],seen={},guard=0;while(d&&d.type!=="disk"&&d.pkname&&guard++<12&&!seen[d.kname]){seen[d.kname]=true;d=blockMap[d.pkname]}return d&&d.type==="disk"?d:inferredDisk(n)}
 function shortDisk(source){var d=diskObject(source);if(!d)return "";var n=String(d.kname||d.name||"");if(/^nvme\d+n\d+$/.test(n)){var m=n.match(/^nvme(\d+)n(\d+)$/);return "NVMe "+m[1]+(m[2]!=="1"?"/"+m[2]:"")}if(/^mmcblk\d+$/.test(n))return "MMC "+n.replace("mmcblk","");var tr=String(d.tran||"").toUpperCase();if(!tr)tr=/^vd/.test(n)?"VirtIO":t("Диск","Disk");return tr+" "+n}
 function detailText(fs,source){var a=[];if(Plasmoid.configuration.showFileSystem&&fs)a.push(fsName(fs));if(Plasmoid.configuration.showPhysicalDisk){var d=shortDisk(source);if(d)a.push(d)}return a.join("  ·  ")}
 function buildBlockMap(data){var map={},a=data.blockdevices||[];for(var i=0;i<a.length;i++){var d=a[i];var o={name:String(d.name||""),kname:String(d.kname||d.name||""),pkname:String(d.pkname||""),type:String(d.type||""),tran:String(d.tran||""),model:String(d.model||"").trim()};if(o.name)map[o.name]=o;if(o.kname)map[o.kname]=o}blockMap=map}
 function parseOutput(s){
  var mark="\n__DC_LSBLK__\n",at=s.indexOf(mark),mountData,blockData
  if(at<0){state="error";errorText=t("Неполный ответ системных утилит","Incomplete system utility output");return}
  try{mountData=JSON.parse(s.substring(0,at));blockData=JSON.parse(s.substring(at+mark.length))}catch(e){state="error";errorText=t("Ошибка разбора сведений о дисках","Cannot parse drive information");return}
  buildBlockMap(blockData)
  var rows=[],seen={},fs=mountData.filesystems||[]
  for(var i=0;i<fs.length;i++){var x=fs[i];if(!allowed(x))continue;var key=cleanSource(x.source)||String(x.target);if(seen[key]!==undefined){var old=rows[seen[key]];if(old.target==="/"||String(old.target).length<=String(x.target).length)continue;rows[seen[key]]=x}else{seen[key]=rows.length;rows.push(x)}}
  rows.sort(function(a,b){if(a.target==="/")return -1;if(b.target==="/")return 1;return nameOf(a).localeCompare(nameOf(b))})
  disks.clear()
  for(var j=0;j<rows.length;j++){var q=rows[j],src=cleanSource(q.source);disks.append({fileSystem:String(q.fstype||""),sourceDevice:src,totalBytes:Number(q.size||0),availableBytes:Number(q.avail||0),usedPercent:Math.max(0,Math.min(100,parseInt(String(q["use%"]||"0"))||0)),mountPath:String(q.target||""),titleText:nameOf(q),iconName:iconOf(q),details:detailText(q.fstype,src)})}
  state="ready";errorText=disks.count?"":t("Доступные диски не найдены","No accessible disks found")
 }
 function refresh(){if(requestRunning){requestPending=true;return}requestRunning=true;if(!disks.count)state="loading";runner.connectSource("LC_ALL=C findmnt --kernel --real --list --bytes --json --output SOURCE,LABEL,FSTYPE,SIZE,AVAIL,USE%,TARGET; printf '\\n__DC_LSBLK__\\n'; LC_ALL=C lsblk --json --list --output NAME,KNAME,PKNAME,TYPE,TRAN,MODEL")}
 function finished(){requestRunning=false;if(requestPending){requestPending=false;Qt.callLater(refresh)}}

 Plasma5Support.DataSource {
  id: runner; engine:"executable"; connectedSources:[]
  onNewData: function(sourceName,data){if(Number(data["exit code"])===0)root.parseOutput(String(data["stdout"]||""));else{root.state="error";root.errorText=String(data["stderr"]||root.t("Ошибка системных утилит","System utility error")).trim()}disconnectSource(sourceName);root.finished()}
 }
 Timer { interval:Math.max(10,Plasmoid.configuration.updateInterval)*1000; running:true; repeat:true; onTriggered:root.refresh() }
 Connections { target:Plasmoid.configuration; function onShowRootChanged(){root.refresh()} function onShowBootChanged(){root.refresh()} function onShowFileSystemChanged(){root.refresh()} function onShowPhysicalDiskChanged(){root.refresh()} }
 Component.onCompleted: refresh()

 fullRepresentation: Item {
  id: view
  implicitWidth: 400
  implicitHeight: root.wantedH
  Layout.minimumWidth: 320
  Layout.preferredWidth: 400
  Layout.minimumHeight: Plasmoid.configuration.autoSize?root.wantedH:160
  Layout.preferredHeight: root.wantedH
  Layout.maximumHeight: Plasmoid.configuration.autoSize?root.wantedH:Number.POSITIVE_INFINITY

  Item {
   id: backdrop; anchors.fill:parent
   readonly property real centralAlpha: Math.max(0,Math.min(1,Plasmoid.configuration.backgroundOpacity/100))
   readonly property real fadeAmount: Math.max(0,Math.min(1,Plasmoid.configuration.edgeFade/100))
   readonly property real edgeAlpha: centralAlpha*(1-fadeAmount)
   readonly property real extraAlpha: edgeAlpha>=0.999?0:Math.max(0,(centralAlpha-edgeAlpha)/(1-edgeAlpha))
   readonly property int fadePixels: Math.max(2,Math.min(64,Plasmoid.configuration.edgeFadeWidth))

   Rectangle {
    anchors.fill:parent
    color:Kirigami.Theme.backgroundColor
    opacity:backdrop.fadeAmount>0?backdrop.edgeAlpha:backdrop.centralAlpha
    radius:Plasmoid.configuration.roundedCorners?Plasmoid.configuration.cornerRadius:0
    antialiasing:true
   }
   Item {
    id: fadeSource
    anchors.fill:parent
    visible:false
    layer.enabled:true
    Rectangle {
     anchors.fill:parent
     anchors.margins:backdrop.fadePixels*0.72
     color:Kirigami.Theme.backgroundColor
     radius:Plasmoid.configuration.roundedCorners?Math.max(0,Plasmoid.configuration.cornerRadius-backdrop.fadePixels*0.3):0
     antialiasing:true
    }
   }
   MultiEffect {
    anchors.fill:parent
    visible:backdrop.fadeAmount>0&&backdrop.extraAlpha>0
    source:fadeSource
    autoPaddingEnabled:false
    blurEnabled:true
    blur:1.0
    blurMax:backdrop.fadePixels
    opacity:backdrop.extraAlpha
   }
  }

  ColumnLayout {
   anchors.fill:parent; anchors.margins:root.pad; spacing:0
   RowLayout {
    Layout.fillWidth:true; Layout.preferredHeight:root.headerH
    Kirigami.Icon { source:"drive-harddisk"; Layout.preferredWidth:Kirigami.Units.iconSizes.smallMedium; Layout.preferredHeight:Layout.preferredWidth }
    Controls.Label { text:root.t("Диски","Disks"); opacity:root.textAlpha; font.bold:true; font.pixelSize:Kirigami.Theme.defaultFont.pixelSize*1.15 }
    Item { Layout.fillWidth:true }
    Controls.Label { text:disks.count; opacity:root.textAlpha; color:Kirigami.Theme.disabledTextColor }
   }
   Item {
    Layout.fillWidth:true; Layout.fillHeight:true; visible:root.state!=="ready"||disks.count===0
    Controls.Label { anchors.centerIn:parent; opacity:root.textAlpha; text:root.state==="loading"?root.t("Поиск дисков…","Searching for disks…"):root.errorText }
   }
   ListView {
    id:list; Layout.fillWidth:true; Layout.fillHeight:true; visible:root.state==="ready"&&disks.count>0
    model:disks; clip:true; boundsBehavior:Flickable.StopAtBounds
    delegate:Item {
     id:card
     required property string fileSystem
     required property string sourceDevice
     required property real totalBytes
     required property real availableBytes
     required property int usedPercent
     required property string mountPath
     required property string titleText
     required property string iconName
     required property string details
     width:ListView.view.width; height:root.rowH
     readonly property color statusColor:usedPercent>=Plasmoid.configuration.criticalPercent?Kirigami.Theme.negativeTextColor:usedPercent>=Plasmoid.configuration.warningPercent?Kirigami.Theme.neutralTextColor:Kirigami.Theme.textColor
     Rectangle { anchors.fill:parent; radius:Plasmoid.configuration.roundedCorners?Math.min(Plasmoid.configuration.cornerRadius,height/2):0; color:hover.containsMouse?Kirigami.Theme.hoverColor:"transparent"; opacity:hover.containsMouse?0.35:0; antialiasing:true }
     RowLayout {
      anchors.fill:parent; anchors.leftMargin:Kirigami.Units.smallSpacing; anchors.rightMargin:Kirigami.Units.smallSpacing; spacing:Kirigami.Units.largeSpacing
      Kirigami.Icon { source:card.iconName; Layout.preferredWidth:Math.min(Kirigami.Units.iconSizes.huge,card.height*0.56); Layout.preferredHeight:Layout.preferredWidth }
      ColumnLayout {
       Layout.fillWidth:true; spacing:2
       Controls.Label { Layout.fillWidth:true; text:card.titleText; opacity:root.textAlpha; font.bold:true; font.pixelSize:Kirigami.Theme.defaultFont.pixelSize*1.1; elide:Text.ElideRight }
       Controls.Label { Layout.fillWidth:true; visible:text.length>0; text:card.details; opacity:root.textAlpha*0.72; color:Kirigami.Theme.disabledTextColor; font.pixelSize:Kirigami.Theme.smallFont.pixelSize; elide:Text.ElideRight }
       Controls.Label { Layout.fillWidth:true; color:card.statusColor; opacity:root.textAlpha; text:root.ru?root.bytes(card.availableBytes)+" свободно из "+root.bytes(card.totalBytes):root.bytes(card.availableBytes)+" free of "+root.bytes(card.totalBytes); elide:Text.ElideRight }
       Controls.ProgressBar { Layout.fillWidth:true; from:0; to:100; value:card.usedPercent }
       Controls.Label { Layout.fillWidth:true; horizontalAlignment:Text.AlignRight; color:card.statusColor; opacity:root.textAlpha; font.pixelSize:Kirigami.Theme.smallFont.pixelSize; text:root.ru?card.usedPercent+"% занято":card.usedPercent+"% used" }
      }
     }
     MouseArea {
      id:hover; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor
      onClicked:Qt.openUrlExternally(root.urlOf(card.mountPath))
      Controls.ToolTip.visible:containsMouse
      Controls.ToolTip.delay:700
      Controls.ToolTip.text:card.mountPath+"\n"+card.sourceDevice+(card.fileSystem?" · "+root.fsName(card.fileSystem):"")
     }
    }
   }
  }
 }
}
