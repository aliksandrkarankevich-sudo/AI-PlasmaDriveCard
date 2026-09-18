import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
 id: page
 property string cfg_language: "ru"
 property alias cfg_updateInterval: interval.value
 property alias cfg_warningPercent: warning.value
 property alias cfg_criticalPercent: critical.value
 property alias cfg_showRoot: showRoot.checked
 property alias cfg_showBoot: showBoot.checked
 property alias cfg_showFileSystem: showFileSystem.checked
 property alias cfg_showPhysicalDisk: showPhysicalDisk.checked
 property alias cfg_autoSize: autoSize.checked
 property alias cfg_rowHeight: rowHeight.value
 property alias cfg_maxAutoHeight: maxHeight.value
 property alias cfg_backgroundOpacity: backgroundOpacity.value
 property alias cfg_textOpacity: textOpacity.value
 property alias cfg_roundedCorners: rounded.checked
 property alias cfg_cornerRadius: radius.value
 property alias cfg_edgeFade: edgeFade.value
 property alias cfg_edgeFadeWidth: fadeWidth.value
 readonly property bool ru: cfg_language === "ru"
 function syncLanguage() { var n=language.indexOfValue(cfg_language); if(n>=0) language.currentIndex=n }
 onCfg_languageChanged: syncLanguage()
 Component.onCompleted: syncLanguage()

 Controls.ComboBox {
  id: language; Kirigami.FormData.label: page.ru?"Язык:":"Language:"
  model: [{text:"Русский",value:"ru"},{text:"English",value:"en"}]
  textRole:"text"; valueRole:"value"; onActivated: page.cfg_language=currentValue
 }
 Kirigami.Separator { Kirigami.FormData.isSection:true }
 Controls.Label { Kirigami.FormData.isSection:true; text:page.ru?"Размер":"Size" }
 Controls.CheckBox { id:autoSize; Kirigami.FormData.label:page.ru?"Высота:":"Height:"; text:page.ru?"Подбирать автоматически":"Fit automatically" }
 Controls.SpinBox { id:rowHeight; Kirigami.FormData.label:page.ru?"Высота строки:":"Row height:"; from:80; to:180; editable:true; textFromValue:function(v){return v+" px"}; valueFromText:function(t){return parseInt(t)} }
 Controls.SpinBox { id:maxHeight; enabled:autoSize.checked; Kirigami.FormData.label:page.ru?"Максимальная высота:":"Maximum height:"; from:240; to:1600; stepSize:20; editable:true; textFromValue:function(v){return v+" px"}; valueFromText:function(t){return parseInt(t)} }
 Controls.CheckBox { id:showRoot; Kirigami.FormData.label:page.ru?"Разделы:":"Volumes:"; text:page.ru?"Показывать системный раздел /":"Show system volume /" }
 Controls.CheckBox { id:showBoot; text:page.ru?"Показывать /boot и /boot/efi":"Show /boot and /boot/efi" }
 Controls.CheckBox { id:showFileSystem; Kirigami.FormData.label:page.ru?"Сведения:":"Details:"; text:page.ru?"Показывать файловую систему":"Show filesystem" }
 Controls.CheckBox { id:showPhysicalDisk; text:page.ru?"Показывать физический диск кратко":"Show physical disk in short form" }

 Kirigami.Separator { Kirigami.FormData.isSection:true }
 Controls.Label { Kirigami.FormData.isSection:true; text:page.ru?"Оформление":"Appearance" }
 Controls.SpinBox { id:backgroundOpacity; Kirigami.FormData.label:page.ru?"Непрозрачность фона:":"Background opacity:"; from:0; to:100; editable:true; textFromValue:function(v){return v+"%"}; valueFromText:function(t){return parseInt(t)} }
 Controls.SpinBox { id:textOpacity; Kirigami.FormData.label:page.ru?"Непрозрачность текста:":"Text opacity:"; from:10; to:100; editable:true; textFromValue:function(v){return v+"%"}; valueFromText:function(t){return parseInt(t)} }
 Controls.CheckBox { id:rounded; Kirigami.FormData.label:page.ru?"Углы:":"Corners:"; text:page.ru?"Включить скругление":"Enable rounded corners" }
 Controls.SpinBox { id:radius; enabled:rounded.checked; Kirigami.FormData.label:page.ru?"Радиус:":"Radius:"; from:0; to:64; editable:true; textFromValue:function(v){return v+" px"}; valueFromText:function(t){return parseInt(t)} }
 Controls.SpinBox { id:edgeFade; Kirigami.FormData.label:page.ru?"Прозрачность края:":"Edge transparency:"; from:0; to:100; editable:true; textFromValue:function(v){return v+"%"}; valueFromText:function(t){return parseInt(t)} }
 Controls.SpinBox { id:fadeWidth; enabled:edgeFade.value>0; Kirigami.FormData.label:page.ru?"Ширина перехода:":"Fade width:"; from:2; to:64; editable:true; textFromValue:function(v){return v+" px"}; valueFromText:function(t){return parseInt(t)} }
 Controls.Label { Kirigami.FormData.isSection:true; text:page.ru?"Переход выполняется непрерывным GPU-размытием без ступеней.":"The edge uses continuous GPU blur without visible bands."; wrapMode:Text.WordWrap; Layout.maximumWidth:420; color:Kirigami.Theme.disabledTextColor }

 Kirigami.Separator { Kirigami.FormData.isSection:true }
 Controls.Label { Kirigami.FormData.isSection:true; text:page.ru?"Обновление":"Updates" }
 Controls.SpinBox { id:interval; Kirigami.FormData.label:page.ru?"Интервал:":"Interval:"; from:10; to:3600; editable:true; textFromValue:function(v){return v+(page.ru?" с":" s")}; valueFromText:function(t){return parseInt(t)} }
 Controls.SpinBox { id:warning; Kirigami.FormData.label:page.ru?"Предупреждение:":"Warning:"; from:1; to:99; textFromValue:function(v){return v+"%"}; valueFromText:function(t){return parseInt(t)} }
 Controls.SpinBox { id:critical; Kirigami.FormData.label:page.ru?"Критический уровень:":"Critical:"; from:2; to:100; textFromValue:function(v){return v+"%"}; valueFromText:function(t){return parseInt(t)} }
}
