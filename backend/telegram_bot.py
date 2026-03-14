import asyncio
import logging
from aiogram import Bot, Dispatcher, types, F
from aiogram.filters import Command
from aiogram.utils.keyboard import ReplyKeyboardBuilder

# Консольге логтарды шығару (қателерді көру үшін)
logging.basicConfig(level=logging.INFO)

# --- КОНФИГУРАЦИЯ ---
API_TOKEN = '8742787172:AAF5QoE3690E-w5G4pfgTOsZTVxa1CH-bsI'
ADMIN_ID = 1048329185  # Сенің жеке ID-ің қосылды

bot = Bot(token=API_TOKEN)
dp = Dispatcher()

# Тіл таңдау батырмалары
def get_lang_keyboard():
    builder = ReplyKeyboardBuilder()
    builder.button(text="🇰🇿 Қазақша")
    builder.button(text="🇷🇺 Русский")
    return builder.as_markup(resize_keyboard=True)

# /start командасы
@dp.message(Command("start"))
async def send_welcome(message: types.Message):
    await message.answer(
        "Сәлем! Тілді таңдаңыз / Здравствуйте! Выберите язык:",
        reply_markup=get_lang_keyboard()
    )

# Тіл таңдалғаннан кейінгі жауап
@dp.message(F.text.in_({"🇰🇿 Қазақша", "🇷🇺 Русский"}))
async def language_set(message: types.Message):
    text = (
        "Рахмет! Сұрағыңызды жазыңыз, біз жақын арада жауап береміз." 
        if "🇰🇿" in message.text else 
        "Спасибо! Напишите ваш вопрос, и мы ответим в ближайшее время."
    )
    # Батырмаларды алып тастап, мәтін жібереміз
    await message.answer(text, reply_markup=types.ReplyKeyboardRemove())

# НЕГІЗГІ ЛОГИКА: Хаттарды өңдеу
@dp.message()
async def handle_messages(message: types.Message):
    # 1. ЕГЕР АДМИН ЖАУАП БЕРСЕ (Клиентке пересылка)
    if message.from_user.id == ADMIN_ID:
        if message.reply_to_message:
            try:
                # Админге келген хаттың бірінші жолынан клиенттің ID-ін аламыз
                first_line = message.reply_to_message.text.split('\n')[0]
                target_user_id = int(first_line.replace("🆔 ID: ", ""))
                
                # Клиентке жауап жіберу
                await bot.send_message(
                    target_user_id, 
                    f"✉️ **Ответ от поддержки Taza Soz:**\n\n{message.text}", 
                    parse_mode="Markdown"
                )
                await message.answer("✅ Жауап клиентке жіберілді!")
            except Exception as e:
                await message.answer(f"❌ Қате шықты: {e}\nЖауап беру үшін клиенттің хатына 'Reply' жасаңыз.")
        return

    # 2. ЕГЕР КЛИЕНТ ЖАЗСА (Админге, яғни саған пересылка)
    # Админге келетін хаттың құрылымы (ОСЫНЫ ӨЗГЕРТПЕ, жауап беру үшін керек)
    admin_report = (
        f"🆔 ID: {message.from_user.id}\n"
        f"👤 Имя: {message.from_user.full_name}\n"
        f"🔗 Username: @{message.from_user.username or 'жоқ'}\n"
        f"---------------------------\n"
        f"📝 ХАТ:\n{message.text}"
    )
    
    # Саған хабарлама жіберу
    await bot.send_message(ADMIN_ID, admin_report)
    
    # Клиентке хаттың кеткенін растау
    feedback = (
        "✅ Хабарламаңыз жіберілді. Жауап күтіңіз." 
        if "🇰🇿" in message.text else 
        "✅ Ваше сообщение отправлено. Ожидайте ответа."
    )
    await message.answer(feedback)

# Ботты іске қосу
async def main():
    print(f"--- Бот сәтті қосылды! Админ ID: {ADMIN_ID} ---")
    await dp.start_polling(bot)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Бот тоқтатылды")