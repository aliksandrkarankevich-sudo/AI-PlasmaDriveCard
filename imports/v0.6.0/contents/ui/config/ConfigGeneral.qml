import QtQuick
import QtQuick.Controls as QQC2
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
 property alias cfg_autoSize: autoSize.checked
 property alias cfg_rowHeight: rowHeight.value
 property alias cfg_backgroundOpacity: backgroundOpacity.value
 property alias cfg_textOpacity: textOpacity.value
 property alias cfg_roundedCorners: rounded.checked
 property alias cfg_cornerRadius: radius.value
 property alias cfg_edgeFade: edgeFade.value
 property alias cfg_edgeFadeWidth: fadeWidth.value
 readonly property bool ru: cfg_language === "ru"
 function syncLanguage() { const i = language.indexOfValue(cfg_language); if (i >= 0) language.currentIndex = i }
 onCfg_languageChanged: syncLanguage()
 Component.onCompleted: syncLanguage()

 QQC2.ComboBox {
  id: language; Kirigami.FormData.label: page.ru ? "Язык:" : "Language:"
  model: [{text:"Русский",value:"ru"},{text:"English",value:"en"}]
  textRole: "text"; valueRole: "value"; onActivated: page.cfg_language = currentValue
 }
 Kirigami.Separator { Kirigami.FormData.isSection: true }
 QQC2.Label { Kirigami.FormData.isSection: true; text: page.ru ? "Размер и содержимое" : "Size and content" }
 QQC2.CheckBox { id:autoSize; Kirigami.FormData.label: page.ru?"Размер:":"Size:"; text:page.ru?"Автоматически подбирать высоту":"Automatically fit height" }
 QQC2.SpinBox { id:rowHeight; Kirigami.FormData.label:page.ru?"Высота строки:":"Row height:"; from:64; to:160; editable:true; textFromValue:function(v){return v+" px"}; valueFromText:function(t){return parseInt(t)} }
 QQC2.CheckBox { id:showRoot; Kirigami.FormData.label:page.ru?"Системные разделы:":"System volumes:"; text:page.ru?"Показывать корневую файловую систему":"Show the root filesystem" }
 QQC2.CheckBox { id:showBoot; text:page.ru?"Показывать /boot и /boot/efi":"Show /boot and /boot/efi" }

 Kirigami.Separator { Kirigami.FormData.isSection: true }
 QQC2.Label { Kirigami.FormData.isSection:true; text:page.ru?"Оформление":"Appearance" }
 QQC2.SpinBox { id:backgroundOpacity; Kirigami.FormData.label:page.ru?"Непрозрачность фона:":"Background opacity:"; from:0; to:100; editable:true; textFromValue:function(v){return v+"%"}; valueFromText:function(t){return parseInt(t)} }
 QQC2.SpinBox { id:textOpacity; Kirigami.FormData.label:page.ru?"Непрозрачность текста:":"Text opacity:"; from:10; to:100; editable:true; textFromValue:function(v){return v+"%"}; valueFromText:function(t){return parseInt(t)} }
 QQC2.CheckBox { id:rounded; Kirigami.FormData.label:page.ru?"Углы:":"Corners:"; text:page.ru?"Включить скругление":"Enable rounded corners" }
 QQC2.SpinBox { id:radius; enabled:rounded.checked; Kirigami.FormData.label:page.ru?"Радиус скругления:":"Corner radius:"; from:0; to:64; editable:true; textFromValue:function(v){return v+" px"}; valueFromText:function(t){return parseInt(t)} }
 QQC2.SpinBox { id:edgeFade; Kirigami.FormData.label:page.ru?"Прозрачность края:":"Edge transparency:"; from:0; to:100; editable:true; textFromValue:function(v){return v+"%"}; valueFromText:function(t){return parseInt(t)} }
 QQC2.SpinBox { id:fadeWidth; enabled:edgeFade.value>0; Kirigami.FormData.label:page.ru?"Ширина перехода:":"Fade width:"; from:1; to:96; editable:true; textFromValue:function(v){return v+" px"}; valueFromText:function(t){return parseInt(t)} }
 Kirigami.InlineMessage { Layout.fillWidth:true; visible:true; type:Kirigami.MessageType.Information; text:page.ru?"100% прозрачности края — плавный переход к полностью прозрачной границе. При нехватке места включается прокрутка.":"100% edge transparency fades to a fully transparent border. Scrolling is enabled when needed." }

 Kirigami.Separator { Kirigami.FormData.isSection:true }
 QQC2.Label { Kirigami.FormData.isSection:true; text:page.ru?"Обновление":"Updates" }
 QQC2.SpinBox { id:interval; Kirigami.FormData.label:page.ru?"Интервал:":"Interval:"; from:10; to:3600; editable:true; textFromValue:function(v){return v+(page.ru?" с":" s")}; valueFromText:function(t){return parseInt(t)} }
 QQC2.SpinBox { id:warning; Kirigami.FormData.label:page.ru?"Предупреждение при:":"Warning at:"; from:1; to:99; textFromValue:function(v){return v+"%"}; valueFromText:function(t){return parseInt(t)} }
 QQC2.SpinBox { id:critical; Kirigami.FormData.label:page.ru?"Критический уровень:":"Critical at:"; from:2; to:100; textFromValue:function(v){return v+"%"}; valueFromText:function(t){return parseInt(t)} }
}
