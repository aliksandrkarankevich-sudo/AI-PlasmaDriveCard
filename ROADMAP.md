# Roadmap

## 0.95.0-beta2 (в работе)

- [x] Убран задвоенный системный фон (`Plasmoid.backgroundHints: NoBackground`).
- [x] Толщина ProgressBar — работает корректно.
- [x] `X-Plasma-BackgroundHints` убран из `metadata.json`.
- [x] `EdgeFadeBackground` переписан на `Canvas` (Qt6-совместимо, без ShaderEffect).
- [ ] Проверка `autoFit` на реальном рабочем столе после фиксации фона.
- [ ] Проверка на реальной системе CachyOS / Plasma 6.
- [ ] Исправления по результатам beta-теста.

## Следующая beta

- [ ] Уточнить сопоставление сложных LUKS/LVM устройств.
- [ ] Проверить визуальное масштабирование Plasma 125–200%.
- [ ] Добавить проверенные снимки экрана в README.

## Стабильная версия 1.0

- [ ] Устранить известные критические ошибки.
- [ ] Проверить обновление с 0.8.1.
- [ ] Подготовить стабильный GitHub Release.

## После 1.0

- [ ] **Мигрировать `EdgeFadeBackground` на QSB-шейдер**  
  Причина: GPU-рендеринг, нулевой CPU даже при анимациях, максимальное качество.  
  Шаги:
  1. Написать `EdgeFade.frag` (GLSL `#version 440`, `layout(std140)` uniforms).
  2. Собрать: `qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o EdgeFade.frag.qsb EdgeFade.frag`  
     *(требует `qt6-shadertools`, только на машине разработчика)*
  3. Заменить `Canvas`-блок на `ShaderEffect { fragmentShader: Qt.resolvedUrl("EdgeFade.frag.qsb") }`.
  4. Закоммитить оба файла (`.frag` + `.qsb`).
