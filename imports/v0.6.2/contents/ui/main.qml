import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
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
 readonly property bool ru: Plasmoid.configuration.language === "ru"
 readonly property real textAlpha: Math.max(0.1,Math.min(1,Plasmoid.configuration.textOpacity/100))
 readonly property int rowH: Math.max(64,Plasmoid.configuration.rowHeight)
 readonly property int headerH: 38
 readonly property int pad: Kirigami.Units.largeSpacing
 readonly property int naturalH: headerH+disks.count*rowH+pad*2
 readonly property int fittedH: Math.max(150,Math.min(naturalH,Math.max(240,Plasmoid.configuration.maxAutoHeight)))
 readonly property int wantedH: Plasmoid.configuration.autoSize?fittedH:260
 Plasmoid.title: ru?"Диски":"Disks"
 Plasmoid.icon: "drive-harddisk"
 Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
 preferredRepresentation: fullRepresentation
 implicitWidth: 380
 implicitHeight: wantedH
 ListModel { id: disks }

 function t(r,e){return ru?r:e}
 function bytes(n){var u=ru?["Б","КиБ","МиБ","ГиБ","ТиБ"]:["B","KiB","MiB","GiB","TiB"],v=Number(n),i=0;while(v>=1024&&i<u.length-1){v/=1024;i++}return Qt.locale(ru?"ru_RU":"en_US").toString(v,"f",i>=3?1:0)+" "+u[i]}
 function nameOf(x){if(x.label&&String(x.label).trim())return String(x.label);if(x.target==="/")return t("Система","System");var a=String(x.target).split("/");return a[a.length-1]||String(x.source)}
 function iconOf(x){var l=String(x.label||"").toLowerCase();if(l.indexOf("game")>=0)return "folder-games";if(x.target==="/")return "drive-harddisk-root";if(String(x.fstype).match(/nfs|cifs/))return "folder-network";return "drive-harddisk"}
 function urlOf(p){return "file://"+String(p).split("/").map(encodeURIComponent).join("/")}
 function allowed(x){var p=String(x.target||"");if(!p||p[0]!=="/")return false;if(!Plasmoid.configuration.showRoot&&p==="/")return false;if(!Plasmoid.configuration.showBoot&&(p==="/boot"||p.indexOf("/boot/")===0))return false;return Number(x.size||0)>0}
 function parseOutput(s){
  var d;try{d=JSON.parse(s)}catch(e){state="error";errorText=t("Ошибка чтения findmnt","Cannot parse findmnt output");return}
  var rows=[],seen={},fs=d.filesystems||[]
  for(var i=0;i<fs.length;i++){var x=fs[i];if(!allowed(x))continue;var key=String(x.source||"").replace(/\[.*\]$/,"")||String(x.target);if(seen[key]!==undefined){var old=rows[seen[key]];if(old.target==="/"||String(old.target).length<=String(x.target).length)continue;rows[seen[key]]=x}else{seen[key]=rows.length;rows.push(x)}}
  rows.sort(function(a,b){if(a.target==="/")return -1;if(b.target==="/")return 1;return nameOf(a).localeCompare(nameOf(b))})
  disks.clear()
  for(var j=0;j<rows.length;j++){var q=rows[j];disks.append({fileSystem:String(q.fstype||""),totalBytes:Number(q.size||0),availableBytes:Number(q.avail||0),usedPercent:Math.max(0,Math.min(100,parseInt(String(q["use%"]||"0"))||0)),mountPath:String(q.target||""),titleText:nameOf(q),iconName:iconOf(q)})}
  state="ready";errorText=disks.count?"":t("Доступные диски не найдены","No accessible disks found")
 }
 function refresh(){if(requestRunning){requestPending=true;return}requestRunning=true;if(!disks.count)state="loading";runner.connectSource("LC_ALL=C findmnt --kernel --real --list --bytes --json --output SOURCE,LABEL,FSTYPE,SIZE,AVAIL,USE%,TARGET")}
 function finished(){requestRunning=false;if(requestPending){requestPending=false;Qt.callLater(refresh)}}

 Plasma5Support.DataSource {
  id: runner; engine:"executable"; connectedSources:[]
  onNewData: function(sourceName,data){if(Number(data["exit code"])===0)root.parseOutput(String(data["stdout"]||""));else{root.state="error";root.errorText=String(data["stderr"]||root.t("Ошибка findmnt","findmnt error")).trim()}disconnectSource(sourceName);root.finished()}
 }
 Timer { interval:Math.max(10,Plasmoid.configuration.updateInterval)*1000; running:true; repeat:true; onTriggered:root.refresh() }
 Connections { target:Plasmoid.configuration; function onShowRootChanged(){root.refresh()} function onShowBootChanged(){root.refresh()} }
 Component.onCompleted: refresh()

 fullRepresentation: Item {
  implicitWidth: 380
  implicitHeight: root.wantedH

  Item {
   id: backdrop; anchors.fill:parent
   readonly property real central: Math.max(0,Math.min(1,Plasmoid.configuration.backgroundOpacity/100))
   readonly property real edge: central*(1-Math.max(0,Math.min(1,Plasmoid.configuration.edgeFade/100)))
   readonly property real band: Math.max(1,Math.min(Math.min(width,height)/2,Plasmoid.configuration.edgeFadeWidth))
   readonly property int count: Plasmoid.configuration.edgeFade>0?10:1
   Repeater {
    model: backdrop.count
    Rectangle {
     required property int index
     readonly property real f: backdrop.count===1?1:index/(backdrop.count-1)
     readonly property real pf: index===0?0:(index-1)/(backdrop.count-1)
     readonly property real desired: backdrop.edge+(backdrop.central-backdrop.edge)*f
     readonly property real prior: index===0?0:backdrop.edge+(backdrop.central-backdrop.edge)*pf
     readonly property real inset: backdrop.count===1?0:backdrop.band*f
     x:inset; y:inset; width:Math.max(0,backdrop.width-inset*2); height:Math.max(0,backdrop.height-inset*2)
     radius:Plasmoid.configuration.roundedCorners?Math.max(0,Plasmoid.configuration.cornerRadius-inset*0.25):0
     color:Kirigami.Theme.backgroundColor
     opacity:prior>=0.999?0:Math.max(0,(desired-prior)/(1-prior))
    }
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
     required property real totalBytes
     required property real availableBytes
     required property int usedPercent
     required property string mountPath
     required property string titleText
     required property string iconName
     width:ListView.view.width; height:root.rowH
     readonly property color statusColor:usedPercent>=Plasmoid.configuration.criticalPercent?Kirigami.Theme.negativeTextColor:usedPercent>=Plasmoid.configuration.warningPercent?Kirigami.Theme.neutralTextColor:Kirigami.Theme.textColor
     Rectangle { anchors.fill:parent; radius:Plasmoid.configuration.roundedCorners?Math.min(Plasmoid.configuration.cornerRadius,height/2):0; color:hover.containsMouse?Kirigami.Theme.hoverColor:"transparent"; opacity:hover.containsMouse?0.35:0 }
     RowLayout {
      anchors.fill:parent; anchors.leftMargin:Kirigami.Units.smallSpacing; anchors.rightMargin:Kirigami.Units.smallSpacing; spacing:Kirigami.Units.largeSpacing
      Kirigami.Icon { source:card.iconName; Layout.preferredWidth:Math.min(Kirigami.Units.iconSizes.huge,card.height*0.62); Layout.preferredHeight:Layout.preferredWidth }
      ColumnLayout {
       Layout.fillWidth:true; spacing:Kirigami.Units.smallSpacing
       Controls.Label { Layout.fillWidth:true; text:card.titleText; opacity:root.textAlpha; font.bold:true; font.pixelSize:Kirigami.Theme.defaultFont.pixelSize*1.1; elide:Text.ElideRight }
       Controls.Label { Layout.fillWidth:true; color:card.statusColor; opacity:root.textAlpha; text:root.ru?root.bytes(card.availableBytes)+" свободно из "+root.bytes(card.totalBytes):root.bytes(card.availableBytes)+" free of "+root.bytes(card.totalBytes); elide:Text.ElideRight }
       Controls.ProgressBar { Layout.fillWidth:true; from:0; to:100; value:card.usedPercent }
       Controls.Label { Layout.fillWidth:true; horizontalAlignment:Text.AlignRight; color:card.statusColor; opacity:root.textAlpha; font.pixelSize:Kirigami.Theme.smallFont.pixelSize; text:root.ru?card.usedPercent+"% занято":card.usedPercent+"% used" }
      }
     }
     MouseArea { id:hover; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:Qt.openUrlExternally(root.urlOf(card.mountPath)) }
    }
   }
  }
 }
}
