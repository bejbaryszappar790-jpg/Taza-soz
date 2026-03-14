import asyncio
import logging
from aiogram import Bot, Dispatcher, types
from aiogram.filters import Command

# Настройка логов, чтобы видеть ошибки в терминале
logging.basicConfig(level=logging.INFO)

API_TOKEN = '8742787172:AAF5QoE3690E-w5G4pfgTOsZTVxa1CH-bsI'

bot = Bot(token=API_TOKEN)
dp = Dispatcher()

@dp.message(Command("start"))
async def send_welcome(message: types.Message):
    # Приветствие на двух языках
    welcome_text = (
        "Сәлем! Taza Soz қолдау қызметіне қош келдіңіз. Сұрағыңызды жазыңыз.\n\n"
        "Здравствуйте! Добро пожаловать в поддержку Taza Soz. Напишите ваш вопрос."
    )
    await message.reply(welcome_text)

@dp.message()
async def handle_message(message: types.Message):
    # Пока мы просто подтверждаем получение
    thanks_text = (
        "Рахмет! Біз сіздің хатыңызды алдық. Жақын арада жауап береміз.\n\n"
        "Спасибо! Мы получили ваше сообщение. Скоро ответим."
    )
    await message.answer(thanks_text)
    
    # В будущем здесь можно добавить пересылку сообщения тебе в личку
    print(f"Новое сообщение от {message.from_user.full_name}: {message.text}")

async def main():
    print("Бот запущен и готов к работе...")
    await dp.start_polling(bot)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Бот остановлен")