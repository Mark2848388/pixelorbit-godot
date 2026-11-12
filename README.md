# Pixel Orbit (Godot 4)

Порт космической survival-игры **Pixel Orbit** на Godot 4.3.

## Что есть сейчас

- Главное меню (Миры / Бесконечный / Кампания)
- Навыки и здания (прокачка, сохранение)
- Боевой цикл: корабль, враги, боссы, волны
- Способности: Импульс (Q) и Заморозка (E)
- 6 миров с разными множителями
- Сохранение прогресса (`user://pixelorbit_save.json`)
- Новые neon pixel-арт спрайты (не из оригинала)
- GitHub Actions → сборка Android APK

## Управление

| Действие | Клавиши / Тач |
|----------|----------------|
| Движение | A/D или ←/→, либо тап/свайп |
| Стрельба | Автоматическая |
| Импульс  | Q |
| Заморозка| E |
| Пауза    | Кнопка на экране |

## Сборка APK

При каждом пуше в `main` GitHub Actions собирает APK.

1. Открой вкладку **Actions**
2. Выбери workflow **Build Android APK**
3. Скачай артефакт `PixelOrbit-APK`

### Локальная сборка

1. Установи [Godot 4.3](https://godotengine.org/download)
2. Открой проект
3. Project → Export → Android
4. Нужен Android SDK + debug keystore (Godot создаст сам при первом экспорте)

## Структура

```
scenes/          — меню, бой, игрок, враги
scripts/
  autoload/      — GameState, SaveManager
  combat/        — игрок, враги, пули, контроллер
  ui/            — меню
assets/sprites/  — новые пиксель-спрайты
.github/workflows/android.yml
```

## Дальше

- Онлайн / Supabase / рейды
- Больше зданий и синергий
- Улучшенный UI под pastel-референсы
- Звук и музыка
- Больше кампанийных уровней

Оригинальная веб-версия: [Mark2848388/pixelorbit](https://github.com/Mark2848388/pixelorbit)
