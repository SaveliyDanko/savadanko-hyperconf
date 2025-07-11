#!/bin/bash

echo "Доступные .desktop-файлы Snap-приложений:"
echo "------------------------------------------"
ls /var/lib/snapd/desktop/applications/ | grep '\.desktop$'
echo "------------------------------------------"

echo "Введите имя .desktop-файла из списка выше:"
echo "(например: telegram-desktop_telegram-desktop.desktop):"
read desktop_file

snap_path="/var/lib/snapd/desktop/applications/$desktop_file"
local_path="$HOME/.local/share/applications/$desktop_file"

# Проверка существования snap-файла
if [ ! -f "$snap_path" ]; then
    echo "❌ Файл $snap_path не найден."
    exit 1
fi

# Создаём директорию, если её нет
mkdir -p "$HOME/.local/share/applications"

# Копируем .desktop-файл
cp "$snap_path" "$local_path"
echo "📄 Скопировано в: $local_path"

# Всегда копируем Exec-параметр из исходного файла
exec_line=$(grep '^Exec=' "$snap_path")
if [ -n "$exec_line" ]; then
    # Удаляем все строки Exec= из локального файла
    sed -i '/^Exec=/d' "$local_path"
    # Убираем env BAMF_DESKTOP_FILE_HINT, если он присутствует
    exec_line=$(echo "$exec_line" | sed -E 's/env BAMF_DESKTOP_FILE_HINT=[^ ]+ //')
    # Вставляем строку Exec сразу после секции [Desktop Entry]
    sed -i "/^\[Desktop Entry\]/a $exec_line" "$local_path"
    echo "✅ Exec установлен: $exec_line"
else
    echo "❌ Exec-параметр не найден в оригинальном файле. Отмена."
    exit 1
fi

# Показываем доступные темы иконок
echo -e "\n🎨 Доступные темы иконок в $HOME/.icons/:"
echo "------------------------------------------"
ls "$HOME/.icons/"
echo "------------------------------------------"

# Запрос пути до иконки
echo "Введите ПОЛНЫЙ путь до вашей иконки (например, /home/savadanko/.icons/mytheme/apps/scalable/telegram.svg):"
read icon_path

if [ ! -f "$icon_path" ]; then
    echo "⚠️ Внимание: указанный файл иконки не существует. Продолжаем, но проверьте путь."
fi

# Удаляем строки с BAMF_DESKTOP_FILE_HINT (если есть)
sed -i '/BAMF_DESKTOP_FILE_HINT/d' "$local_path"

# Обновляем (или добавляем) строку Icon
if grep -q '^Icon=' "$local_path"; then
    sed -i "s|^Icon=.*|Icon=$icon_path|" "$local_path"
else
    sed -i "/^\[Desktop Entry\]/a Icon=$icon_path" "$local_path"
fi

echo "✅ Параметр Icon установлен: $icon_path"

# Делаем .desktop-файл исполняемым
chmod +x "$local_path"

echo -e "\n🎉 Готово! Локальный ярлык создан с вашей иконкой:"
echo "$local_path"
echo "📌 Перезапустите оболочку (или nautilus), чтобы увидеть изменения."
