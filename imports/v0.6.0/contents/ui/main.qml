import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
 id: root
 property string state:"loading"
 property string errorText:""
 property bool requestRunning:false
 property bool requestPending:false
 readonly property bool ru: Plasmoid.configuration.language === "ru"
 readonly property real textAlpha: Math.max(.1,Math.min(1,Plasmoid.configuration.textOpacity/100))
 readonly property int rowH: Math.max(64,Plasmoid.configuration.rowHeight)
 readonly property int headerH: 38
 readonly property int margin: Kirigami.Units.largeSpacing
 readonly property int naturalH: headerH + disks.count*rowH + margin*2
 readonly property int screenH: Screen.desktopAvailableHeight>0 ? Screen.desktopAvailableHeight : 900
 readonly property int fittedH: Math.max(150,Math.min(naturalH,Math.round(screenH*.82)))
 readonly property int wantedH: Plasmoid.configuration.autoSize ? fittedH : 260

 Plasmoid.title: ru?"Диски":"Disks"
 Plasmoid.icon:"drive-harddisk"
 Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
 preferredRepresentation: fullRepresentation
 width:380; height:wantedH; implicitWidth:380; implicitHeight:wantedH
 Layout.minimumWidth:300
 Layout.minimumHeight: Plasmoid.configuration.autoSize ? fittedH : 150
 Layout.preferredWidth:380
 Layout.preferredHeight:wantedH

 ListModel { id:disks }
 function tr(r,e){return ru?r:e}
 function fmt(n){let u=ru?["Б","КиБ","МиБ","ГиБ","ТиБ","ПиБ"]:["B","KiB","MiB","GiB","TiB","PiB"],v=Number(n),i=0;while(v>=1024&&i<u.length-1){v/=1024;i++}return Qt.locale(ru?"ru_RU":"en_US").toString(v,"f",i>=3?1:0)+" "+u[i]}
 function titleOf(x){if(x.label&&String(x.label).trim())return String(x.label);if(x.target==="/")return tr("Система","System");if(x.target==="/home")return tr("Домашний раздел","Home");let a=String(x.target).split("/");return a[a.length-1]||String(x.source)}
 function iconOf(x){let l=String(x.label||"").toLowerCase();if(l.indexOf("game")>=0)return "folder-games";if(x.target==="/")return "drive-harddisk-root";if(String(x.fstype).match(/nfs|cifs/))return "folder-network";return "drive-harddisk"}
 function urlOf(p){return "file://"+String(p).split("/").map(encodeURIComponent).join("/")}
 function allowed(x){let t=String(x.target||"");if(!t||t[0]!=="/")return false;if(!Plasmoid.configuration.showRoot&&t==="/")return false;if(!Plasmoid.configuration.showBoot&&(t==="/boot"||t.indexOf("/boot/")===0))return false;return Number(x.size||0)>0}
 function parse(s){let d;try{d=JSON.parse(s)}catch(e){state="error";errorText=tr("Ошибка чтения findmnt","Cannot parse findmnt output");return}let a=[],seen={};for(let x of (d.filesystems||[])){if(!allowed(x))continue;let key=String(x.source||"").replace(/\[.*\]$/,"")||String(x.target);if(seen[key]!==undefined){let old=a[seen[key]];if(old.target==="/"||String(old.target).length<=String(x.target).length)continue;a[seen[key]]=x}else{seen[key]=a.length;a.push(x)}}a.sort((x,y)=>x.target==="/"?-1:y.target==="/"?1:titleOf(x).localeCompare(titleOf(y)));disks.clear();for(let x of a){disks.append({sourcePath:String(x.source||""),volumeLabel:String(x.label||""),fileSystem:String(x.fstype||""),totalBytes:Number(x.size||0),availableBytes:Number(x.avail||0),usedPercent:Math.max(0,Math.min(100,parseInt(String(x["use%"]||"0"))||0)),mountPath:String(x.target||""),title:titleOf(x),iconName:iconOf(x)})}state="ready";errorText=disks.count?"":tr("Доступные диски не найдены","No accessible disks found")}
 function refresh(){if(requestRunning){requestPending=true;return}requestRunning=true;if(!disks.count)state="loading";exec.connectSource("LC_ALL=C findmnt --kernel --real --list --bytes --json --output SOURCE,LABEL,FSTYPE,SIZE,AVAIL,USE%,TARGET")}
 function done(){requestRunning=false;if(requestPending){requestPending=false;Qt.callLater(refresh)}}

 Plasma5Support.DataSource { id:exec; engine:"executable"; connectedSources:[]; onNewData:(source,data)=>{if(Number(data["exit code"])===0)root.parse(String(data["stdout"]||""));else{root.state="error";root.errorText=String(data["stderr"]||root.tr("Ошибка findmnt","findmnt error")).trim()}disconnectSource(source);root.done()} }
 Timer { interval:Math.max(10,Plasmoid.configuration.updateInterval)*1000; running:true; repeat:true; onTriggered:root.refresh() }
 Connections { target:Plasmoid.configuration; function onShowRootChanged(){root.refresh()} function onShowBootChanged(){root.refresh()} }
 Component.onCompleted:refresh()

 fullRepresentation: Item {
  readonly property var appletInterface: Plasmoid
  implicitWidth:380; implicitHeight:root.wantedH
  Layout.minimumWidth:300
  Layout.minimumHeight:Plasmoid.configuration.autoSize?root.fittedH:150
  Layout.preferredWidth:380
  Layout.preferredHeight:root.wantedH

  Canvas {
   id:bg; anchors.fill:parent; antialiasing:true
   property color c:Kirigami.Theme.backgroundColor
   property real centerA:Math.max(0,Math.min(1,Plasmoid.configuration.backgroundOpacity/100))
   property real edgeA:centerA*(1-Math.max(0,Math.min(1,Plasmoid.configuration.edgeFade/100)))
   property real r:Plasmoid.configuration.roundedCorners?Math.max(0,Plasmoid.configuration.cornerRadius):0
   property real fw:Math.max(1,Math.min(Math.min(width,height)/2,Plasmoid.configuration.edgeFadeWidth))
   function path(ctx,x,y,w,h,r0){let q=Math.max(0,Math.min(r0,Math.min(w,h)/2));ctx.beginPath();ctx.moveTo(x+q,y);ctx.lineTo(x+w-q,y);ctx.quadraticCurveTo(x+w,y,x+w,y+q);ctx.lineTo(x+w,y+h-q);ctx.quadraticCurveTo(x+w,y+h,x+w-q,y+h);ctx.lineTo(x+q,y+h);ctx.quadraticCurveTo(x,y+h,x,y+h-q);ctx.lineTo(x,y+q);ctx.quadraticCurveTo(x,y,x+q,y);ctx.closePath()}
   onPaint:{let x=getContext("2d");x.clearRect(0,0,width,height);if(centerA<=0)return;let fade=Plasmoid.configuration.edgeFade/100;if(fade<=.001){x.fillStyle=Qt.rgba(c.r,c.g,c.b,centerA);path(x,0,0,width,height,r);x.fill();return}let steps=Math.max(12,Math.min(40,Math.round(fw))),acc=0;for(let i=0;i<=steps;i++){let t=i/steps,want=edgeA+(centerA-edgeA)*(t*t*(3-2*t)),la=acc>=.999?0:(want-acc)/(1-acc),ins=fw*t,w=width-2*ins,h=height-2*ins;if(w<=0||h<=0)break;x.fillStyle=Qt.rgba(c.r,c.g,c.b,Math.max(0,la));path(x,ins,ins,w,h,Math.max(0,r-ins*.35));x.fill();acc=want}}
   onWidthChanged:requestPaint(); onHeightChanged:requestPaint(); onCChanged:requestPaint(); onCenterAChanged:requestPaint(); onEdgeAChanged:requestPaint(); onRChanged:requestPaint(); onFwChanged:requestPaint()
  }

  ColumnLayout {
   anchors.fill:parent; anchors.margins:root.margin; spacing:0
   RowLayout { Layout.fillWidth:true; Layout.preferredHeight:root.headerH
    Kirigami.Icon { source:"drive-harddisk"; Layout.preferredWidth:Kirigami.Units.iconSizes.smallMedium; Layout.preferredHeight:Layout.preferredWidth }
    QQC2.Label { text:root.tr("Диски","Disks"); opacity:root.textAlpha; font.bold:true; font.pixelSize:Kirigami.Theme.defaultFont.pixelSize*1.15 }
    Item { Layout.fillWidth:true }
    QQC2.Label { text:disks.count; opacity:root.textAlpha; color:Kirigami.Theme.disabledTextColor }
   }
   Item { Layout.fillWidth:true; Layout.fillHeight:true; visible:root.state!=="ready"||!disks.count
    Column { anchors.centerIn:parent; spacing:Kirigami.Units.smallSpacing
     Kirigami.Icon { anchors.horizontalCenter:parent.horizontalCenter; source:root.state==="error"?"dialog-error":"view-refresh"; width:Kirigami.Units.iconSizes.large; height:width }
     QQC2.Label { anchors.horizontalCenter:parent.horizontalCenter; opacity:root.textAlpha; text:root.state==="loading"?root.tr("Поиск дисков…","Searching for disks…"):root.errorText }
    }
   }
   ListView { id:list; Layout.fillWidth:true; Layout.fillHeight:true; visible:root.state==="ready"&&disks.count>0; model:disks; clip:true; boundsBehavior:Flickable.StopAtBounds
    ScrollBar.vertical: QQC2.ScrollBar { policy:list.contentHeight>list.height?QQC2.ScrollBar.AsNeeded:QQC2.ScrollBar.AlwaysOff }
    delegate:Item { id:card
     required property string sourcePath; required property string volumeLabel; required property string fileSystem; required property real totalBytes; required property real availableBytes; required property int usedPercent; required property string mountPath; required property string title; required property string iconName
     width:ListView.view.width-(list.contentHeight>list.height?Kirigami.Units.smallSpacing:0); height:root.rowH
     readonly property color statusColor:usedPercent>=Plasmoid.configuration.criticalPercent?Kirigami.Theme.negativeTextColor:usedPercent>=Plasmoid.configuration.warningPercent?Kirigami.Theme.neutralTextColor:Kirigami.Theme.textColor
     Rectangle { anchors.fill:parent; radius:Plasmoid.configuration.roundedCorners?Math.min(Plasmoid.configuration.cornerRadius,height/2):0; color:mouse.containsMouse?Kirigami.Theme.hoverColor:"transparent"; opacity:mouse.containsMouse?.35:0 }
     RowLayout { anchors.fill:parent; anchors.leftMargin:Kirigami.Units.smallSpacing; anchors.rightMargin:Kirigami.Units.smallSpacing; spacing:Kirigami.Units.largeSpacing
      Kirigami.Icon { source:card.iconName; Layout.preferredWidth:Math.min(Kirigami.Units.iconSizes.huge,card.height*.62); Layout.preferredHeight:Layout.preferredWidth }
      ColumnLayout { Layout.fillWidth:true; spacing:Kirigami.Units.smallSpacing
       QQC2.Label { Layout.fillWidth:true; text:card.title; opacity:root.textAlpha; font.bold:true; font.pixelSize:Kirigami.Theme.defaultFont.pixelSize*1.1; elide:Text.ElideRight }
       QQC2.Label { Layout.fillWidth:true; color:card.statusColor; opacity:root.textAlpha; text:root.ru?root.fmt(card.availableBytes)+" свободно из "+root.fmt(card.totalBytes):root.fmt(card.availableBytes)+" free of "+root.fmt(card.totalBytes); elide:Text.ElideRight }
       QQC2.ProgressBar { Layout.fillWidth:true; from:0; to:100; value:card.usedPercent }
       QQC2.Label { Layout.fillWidth:true; horizontalAlignment:Text.AlignRight; color:card.statusColor; opacity:root.textAlpha; font.pixelSize:Kirigami.Theme.smallFont.pixelSize; text:root.ru?card.usedPercent+"% занято":card.usedPercent+"% used" }
      }
     }
     MouseArea { id:mouse; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:Qt.openUrlExternally(root.urlOf(card.mountPath)) }
     QQC2.ToolTip.visible:mouse.containsMouse
     QQC2.ToolTip.text:root.ru?card.mountPath+"\n"+card.fileSystem+" · нажмите, чтобы открыть":card.mountPath+"\n"+card.fileSystem+" · click to open"
    }
   }
  }
 }
}
