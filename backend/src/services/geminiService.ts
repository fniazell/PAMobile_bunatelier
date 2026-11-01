import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import { GoogleGenAI, ThinkingLevel } from '@google/genai';
import { config } from '../config/env.js';

export interface ChatHistoryItem {
  role: 'user' | 'model';
  text: string;
}

export interface CurrencyContextPayload {
  queryType?: 'product' | 'product_not_found' | 'cart' | 'cart_empty';
  productName?: string;
  originalPriceIdr?: number;
  searchedTerm?: string;
  cartItemCount?: number;
  cartGrandTotalIdr?: number;
  targetCurrency?: string;
  convertedAmount?: number;
  formattedConverted?: string;
  rateInfoText?: string;
  rateSource?: string;
  isEnglishQuery?: boolean;
}

const SYSTEM_INSTRUCTION = `
Kamu adalah "Bun Atelier Concierge" & "Bun Buddy AI" — Customer Support dan Konsultan Burger resmi untuk Bun Atelier, gerai burger artisanal premium dengan tagline "Worth the Mess."

Tugas dan Karaktermu:
1. BAHASA & NADA BICARA:
   - Selalu berkomunikasi dalam Bahasa Indonesia yang ramah, hangat, santai tapi sopan, antusias, dan solutif.
   - Pahami bahasa kasual, singkatan, dan slang Indonesia (misal: "pedes", "pedas", "berapaan", "mager", "rekomendasiin", "lokasi", "cabang").
   - JANGAN PERNAH gunakan tanda bintang atau asterisk (* atau **) sama sekali! Dilarang menggunakan format markdown tebal (**kata**) ataupun miring (*kata*).
   - Untuk daftar atau poin, gunakan bullet titik (•), nomor (1, 2, 3), atau strip (-). Jangan gunakan tanda bintang.
   - Buat teks tampil bersih, rapi, dan nyaman dibaca di layar HP tanpa simbol markdown mentah.

2. PENGETAHUAN RESMI MENU LENGKAP BUN ATELIER:
   - KATEGORI BURGER UTAMA:
     • Truffle Butter Truce: Rp 85.000 (BURGER PALING MAHAL / MEWAH — 100% Wagyu blend patty, black truffle butter, truffle aioli, melted aged cheddar).
     • The Hangover Cure: Rp 82.000 (Double smashed Australian beef, crispy beef bacon, sunny egg, hash brown crumble, smoked BBQ sauce).
     • No Cap Double Smash: Rp 78.000 (Triple aged cheddar, double smashed beef, caramelized onions, molten cheese dip).
     • OG Main Character: Rp 72.000 (BEST-SELLER JUARA — signature double smashed Australian beef patty, double cheddar, secret relish sauce).
     • Hot Mess Express: Rp 72.000 (EKSTRA PEDAS — habanero pepper jam membakar, ghost pepper mayo, crispy jalapeno).
     • Lowkey Spicy: Rp 64.000 (PEDAS SEDANG — chipotle lime mayo, pickled jalapeno, pepper jack cheese).
     • Crunch Culture: Rp 59.000 (24-hr brined crispy buttermilk chicken thigh, garlic herb aioli, fresh slaw).
     • Touch Grass: Rp 58.000 (BURGER PALING MURAH / TERJANGKAU & PLANT-BASED — 100% vegetarian shiitake mushroom & black bean patty, vegan truffle mayo).

   - KATEGORI CROISSANT BURGER (FLAKY BUTTER BUNS):
     • Smoked Bacon & Brie Croissant: Rp 76.000 (Beef bacon, molten French brie cheese, caramelized balsamic onions).
     • Truffle Wagyu Croissant Smash: Rp 74.000 (Hand-rolled butter croissant bun, smashed Angus patty, truffle soft scramble, French emmental cheese).
     • Morning Pastrami Croissant Burger: Rp 69.000 (Spiral croissant, cured pastrami beef, sunny egg, aged cheddar, sweet relish).
     • Crispy Chicken Avocado Croissant Burger: Rp 66.000 (Crispy buttermilk chicken thigh, fresh avocado smash, garlic herb aioli).

   - KATEGORI SIDE QUEST (CEMILAN PENDAMPING):
     • Crispy Hash Brown: Rp 22.000 (Golden shredded potato patty renyah garing).
     • Crispy French Fries: Rp 25.000 (Kentang goreng renyah bumbu sea salt).
     • Beer-Battered Onion Rings: Rp 28.000 (Bawang bombay tepung renyah dengan garlic aioli).
     • Truffle Mac n Cheese: Rp 38.000 (Pasta elbow dengan 5 jenis keju leleh dan white truffle oil).
     • Smoky Buffalo Chicken Wings: Rp 48.000 (6 pcs sayap ayam saus cayenne pepper pedas gurih).

   - KATEGORI DRINKS (MINUMAN SEGAR):
     • Aqua Reflections Mineral Water: Rp 15.000 (Air mineral alami pegunungan botol kaca premium).
     • Coca-Cola Classic / Sprite Crisp Lemon / Fanta Orange Spark: Rp 18.000 (Disajikan dingin dengan es batu).
     • Dr Pepper: Rp 20.000
     • Fresh Iced Lemon Tea: Rp 22.000 (Seduhan teh Ceylon, perasan lemon Sunkist asli, dan madu murni).
     • Atelier Berry Slushie: Rp 32.000 (Frozen blend strawberry, blueberry, raspberry segar).
     • Vintage Root Beer Float: Rp 35.000 (Sarsaparilla root beer dengan topping 1 scoop Madagascar vanilla gelato).

   - KATEGORI DESSERTS (HIDANGAN PENUTUP MANIS RESMI):
     • Belgian Waffle Ice Cream: Rp 38.000 (Best-Seller Dessert — Liège waffle hangat dengan salted caramel gelato dan roasted pecans).
     • Artisan Gelato Cup: Rp 28.000 (Double scoop gelato buatan tangan pilihan French Vanilla & Dark Chocolate Fudge).
     • Triple Choc Melt Muffin: Rp 26.000 (Muffin cokelat lezat dengan isian lelehan molten fudge hangat).
     • Fluffy Souffle Pancake: Rp 42.000 (Pancake soufflé lembut mengembang ala Jepang dengan butter dan wild berry compote).
     • Vanilla Bean Panna Cotta: Rp 32.000 (Panna cotta lembut dengan passionfruit coulis segar).

3. OUTLET RESMI:
   - Senopati Flagship: Jl. Senopati No. 45, Kebayoran Baru, Jakarta Selatan (Buka: 10:00 - 23:00 WIB, Telp: +62 21 555-BURGER).
   - PIK 2 Waterfront: Pantai Indah Kapuk 2, Boulevard Raya No. 12, Jakarta Utara (Buka: 11:00 - 00:00 WIB, Telp: +62 21 555-PIKBUN).
   - Buka setiap hari (Senin - Minggu) termasuk tanggal merah / libur nasional.

4. KEHALALAN & BAHAN:
   - 100% No Pork, No Lard, No Alcohol.
   - Menggunakan Australian Halal-Certified Beef & Wagyu Blend, ayam segar bersertifikat, dan bahan-bahan premium berkualitas tinggi.

5. PEMBAYARAN & PENGIRIMAN:
   - Mendukung Bayar di Tempat (COD), E-Wallet (GoPay, OVO, DANA, ShopeePay), Transfer Bank, dan Kartu Kredit/Debit. Estimasi kirim 30-60 menit.

6. PANDUAN MENJAWAB:
   - Jawab pertanyaan spesifik dengan lugas, informatif, dan menyebutkan nama produk serta harga secara tepat.
   - Jika ditanya burger paling mahal: langsung sebut Truffle Butter Truce (Rp 85.000).
   - Jika ditanya burger paling murah: langsung sebut Touch Grass (Rp 58.000) dan Crunch Culture (Rp 59.000).
   - Bersikap proaktif menawarkan bantuan pemesanan atau pendamping menu.
`.trim();

export function cleanAsterisks(text: string): string {
  if (!text) return text;
  return text
    .replace(/\*\*(.*?)\*\*/g, '$1')
    .replace(/\*([^\*\n]+?)\*/g, '$1')
    .replace(/^[\s]*\*[\s]+/gm, '• ')
    .replace(/\*/g, '')
    .trim();
}

function buildAlternatingContents(
  history: ChatHistoryItem[],
  userMessage: string
): Array<{ role: 'user' | 'model'; parts: Array<{ text: string }> }> {
  const sanitized: Array<{ role: 'user' | 'model'; text: string }> = [];

  for (const item of history) {
    const text = typeof item.text === 'string' ? item.text.trim() : '';
    if (!text) continue;
    if (item.role !== 'user' && item.role !== 'model') continue;

    if (sanitized.length === 0) {
      if (item.role === 'user') {
        sanitized.push({ role: 'user', text });
      }
    } else {
      const last = sanitized[sanitized.length - 1];
      if (last.role === item.role) {
        last.text += `\n${text}`;
      } else {
        sanitized.push({ role: item.role, text });
      }
    }
  }

  // Ensure last history item before new user message is 'model'
  if (sanitized.length > 0 && sanitized[sanitized.length - 1].role === 'user') {
    sanitized.pop();
  }

  // Keep last 8 turns (4 pairs) to stay within limits and maintain high speed
  const recent = sanitized.slice(-8);

  const contents: Array<{ role: 'user' | 'model'; parts: Array<{ text: string }> }> = recent.map(
    (item) => ({
      role: item.role,
      parts: [{ text: item.text }],
    })
  );

  contents.push({
    role: 'user',
    parts: [{ text: userMessage.trim() }],
  });

  return contents;
}

function getSmartConciergeReply(
  userMessage: string,
  currencyContext?: CurrencyContextPayload
): string {
  // If currency context was resolved, return precise ground-truth conversion
  if (currencyContext) {
    const isEn = currencyContext.isEnglishQuery === true;
    const target = currencyContext.targetCurrency || 'USD';
    const formattedTarget = currencyContext.formattedConverted || '';

    if (currencyContext.queryType === 'product') {
      const pName = currencyContext.productName || 'Burger';
      const pPrice = currencyContext.originalPriceIdr
        ? `Rp ${currencyContext.originalPriceIdr.toLocaleString('id-ID')}`
        : 'sesuai katalog';
      return isEn
        ? `${pName} costs ${pPrice}. Based on the latest available exchange rate, that is approximately ${formattedTarget}. The final checkout amount remains in IDR.`
        : `Harga ${pName} adalah ${pPrice}. Berdasarkan kurs terbaru, perkiraannya adalah sekitar ${formattedTarget}. Pembayaran akhir pesanan tetap dalam IDR (Rupiah).`;
    }

    if (currencyContext.queryType === 'product_not_found') {
      const term = currencyContext.searchedTerm || 'yang dicari';
      return isEn
        ? `The product '${term}' was not found in Bun Atelier's current menu. We offer signature burgers like OG Main Character, Smash Hit, Hot Mess Express, and Truffle Butter Truce. Which one would you like to check?`
        : `Menu '${term}' belum ditemukan di katalog Bun Atelier saat ini. Kami memiliki pilihan burger favorit seperti OG Main Character, Smash Hit, Hot Mess Express, dan Truffle Butter Truce. Mau cek harga salah satunya?`;
    }

    if (currencyContext.queryType === 'cart') {
      const total = currencyContext.cartGrandTotalIdr
        ? `Rp ${currencyContext.cartGrandTotalIdr.toLocaleString('id-ID')}`
        : 'di keranjang';
      const count = currencyContext.cartItemCount || 0;
      return isEn
        ? `Your current cart total is ${total} (${count} items, including tax and delivery). Based on the latest available exchange rate, that is approximately ${formattedTarget}. The final payment at checkout remains in IDR.`
        : `Perkiraan total belanja keranjangmu saat ini adalah ${total} (${count} item, termasuk pajak & ongkir). Berdasarkan kurs terbaru, nilainya sekitar ${formattedTarget}. Pembayaran akhir saat checkout tetap menggunakan IDR (Rupiah).`;
    }

    if (currencyContext.queryType === 'cart_empty') {
      return isEn
        ? `Your cart is currently empty! Add some delicious burgers or sides first, and I will gladly calculate the total in ${target} for you.`
        : `Keranjang belanjamu saat ini masih kosong nih. Yuk pilih burger atau cemilan lezat dulu di menu, nanti kubantu hitungkan perkiraan totalnya dalam ${target}!`;
    }
  }

  const lower = userMessage.toLowerCase();

  // 1. BURGER PALING MAHAL / MEWAH
  if (
    lower.includes('paling mahal') ||
    lower.includes('termahal') ||
    lower.includes('mewah') ||
    lower.includes('pricey') ||
    (lower.includes('mahal') && (lower.includes('burger') || lower.includes('menu')))
  ) {
    return 'Burger paling mewah dan juara dari segi harga di Bun Atelier adalah Truffle Butter Truce seharga Rp 85.000!\n\nBurger ini diracik dengan premium Wagyu blend patty yang sangat juicy, black truffle butter harum, truffle aioli lezat, dan melted aged cheddar.\n\nUntuk kategori Croissant Burger, yang paling premium adalah Smoked Bacon & Brie Croissant (Rp 76.000) dan Truffle Wagyu Croissant Smash (Rp 74.000).\n\nMau pesan yang mewah seperti Truffle Butter Truce hari ini?';
  }

  // 2. BURGER PALING MURAH / HEMAT / BUDGET
  if (
    lower.includes('paling murah') ||
    lower.includes('termurah') ||
    lower.includes('hemat') ||
    lower.includes('budget') ||
    lower.includes('terjangkau') ||
    (lower.includes('murah') && (lower.includes('burger') || lower.includes('menu')))
  ) {
    return 'Pilihan burger paling hemat dan bersahabat di Bun Atelier adalah:\n• Touch Grass: Rp 58.000 (Burger plant-based nabati dengan patty jamur shiitake dan vegan truffle mayo)\n• Crunch Culture: Rp 59.000 (Ayam buttermilk goreng renyah maksimal dengan saus garlic herb aioli)\n\nUntuk menu sides pendamping hemat, kami ada Crispy Hash Brown (Rp 22.000) dan Crispy French Fries (Rp 25.000). Tetap nikmat dan ramah di kantong!';
  }

  // 3. BURGER PEDAS
  if (
    lower.includes('pedas') ||
    lower.includes('pedes') ||
    lower.includes('spicy') ||
    lower.includes('hot')
  ) {
    return 'Untuk pencinta pedas, kami sangat merekomendasikan:\n• Hot Mess Express (Rp 72.000) - Level pedas juara dengan habanero jam membakar, ghost pepper mayo, dan crispy jalapeno renyah!\n• Lowkey Spicy (Rp 64.000) - Pedas santai gurih dengan chipotle lime mayo dan pickled jalapeno.\n\nPasti bikin nagih dan mata melek!';
  }

  // 4. CROISSANT BURGER
  if (
    lower.includes('croissant') ||
    lower.includes('pastrami') ||
    lower.includes('avocado') ||
    lower.includes('brie')
  ) {
    return 'Bun Atelier punya 4 menu Croissant Burger istimewa dengan roti croissant French butter yang flaky dan harum:\n1. Truffle Wagyu Croissant Smash (Rp 74.000) - Smashed Angus patty, truffle soft scramble, dan melted French emmental.\n2. Smoked Bacon & Brie Croissant (Rp 76.000) - Crispy beef bacon, French brie melt, dan caramelized balsamic onions.\n3. Morning Pastrami Croissant Burger (Rp 69.000) - Beef pastrami, sunny egg, dan yellow cheddar.\n4. Crispy Chicken Avocado Croissant Burger (Rp 66.000) - Buttermilk chicken thigh renyah dengan avocado smash segar.\n\nSensasi flaky croissant-nya wajib kamu coba!';
  }

  // 5. DESSERT / MANIS
  if (
    lower.includes('dessert') ||
    lower.includes('manis') ||
    lower.includes('waffle') ||
    lower.includes('gelato') ||
    lower.includes('ice cream') ||
    lower.includes('es krim') ||
    lower.includes('muffin') ||
    lower.includes('pancake') ||
    lower.includes('panna cotta') ||
    lower.includes('kue') ||
    lower.includes('penutup')
  ) {
    return 'Ada dong! Di Bun Atelier kita punya 5 menu dessert lezat yang manis dan pas banget buat penutup makan burger kamu:\n\n1. Belgian Waffle Ice Cream (Rp 38.000) - Liege waffle hangat dengan topping salted caramel gelato dan roasted pecans (Best-Seller!)\n2. Artisan Gelato Cup (Rp 28.000) - Double scoop gelato buatan tangan pilihan French Vanilla & Dark Chocolate Fudge\n3. Triple Choc Melt Muffin (Rp 26.000) - Muffin cokelat lezat dengan isian lelehan molten fudge hangat\n4. Fluffy Souffle Pancake (Rp 42.000) - Pancake soufflé lembut mengembang ala Jepang dengan butter dan wild berry compote\n5. Vanilla Bean Panna Cotta (Rp 32.000) - Panna cotta lembut dengan passionfruit coulis segar\n\nMau pesan dessert yang mana untuk melengkapi pesananmu hari ini?';
  }

  // 6. SIDES / CEMILAN
  if (
    lower.includes('side') ||
    lower.includes('kentang') ||
    lower.includes('fries') ||
    lower.includes('hash brown') ||
    lower.includes('onion') ||
    lower.includes('mac') ||
    lower.includes('wings') ||
    lower.includes('cemilan')
  ) {
    return 'Berikut pilihan Side Quest (cemilan pendamping) lezat di Bun Atelier:\n• Crispy Hash Brown (Rp 22.000) - Patty kentang parut renyah keemasan\n• Crispy French Fries (Rp 25.000) - Kentang goreng renyah bergaram laut\n• Beer-Battered Onion Rings (Rp 28.000) - Bawang bombay goreng tepung renyah dengan garlic aioli\n• Truffle Mac n Cheese (Rp 38.000) - Elbow pasta dengan 5 keju leleh dan white truffle oil\n• Smoky Buffalo Chicken Wings (Rp 48.000) - 6 pcs sayap ayam pedas gurih\n\nFavorit pelanggan kami adalah Truffle Mac n Cheese dan Crispy Hash Brown!';
  }

  // 7. DRINKS / MINUMAN
  if (
    lower.includes('minum') ||
    lower.includes('drink') ||
    lower.includes('air') ||
    lower.includes('aqua') ||
    lower.includes('soda') ||
    lower.includes('slushie') ||
    lower.includes('tea') ||
    lower.includes('teh') ||
    lower.includes('haus') ||
    lower.includes('float')
  ) {
    return 'Untuk pelepas dahaga, Bun Atelier menyediakan:\n• Aqua Reflections Mineral Water: Rp 15.000 (Air mineral alami botol kaca premium)\n• Coca-Cola Classic / Sprite / Fanta Orange: Rp 18.000\n• Dr Pepper: Rp 20.000\n• Fresh Iced Lemon Tea: Rp 22.000 (Teh Ceylon segar dengan lemon asli dan madu)\n• Atelier Berry Slushie: Rp 32.000 (Blended strawberry, blueberry & raspberry segar)\n• Vintage Root Beer Float: Rp 35.000 (Root beer klasik dengan 1 scoop vanilla gelato)';
  }

  // 8. KEHALALAN
  if (
    lower.includes('halal') ||
    lower.includes('babi') ||
    lower.includes('pork') ||
    lower.includes('lard') ||
    lower.includes('alkohol')
  ) {
    return 'Semua menu di Bun Atelier 100% No Pork No Lard! Daging sapi kami bersertifikat Australian Halal Beef & Wagyu Blend, ayam segar pilihan, serta seluruh proses pengolahan diawasi ketat tanpa bahan non-halal. Kamu bisa bersantap dengan aman dan nyaman!';
  }

  // 9. REKOMENDASI / MENU POPULER
  if (
    lower.includes('rekomendasi') ||
    lower.includes('laris') ||
    lower.includes('best seller') ||
    lower.includes('favorit') ||
    lower.includes('enak') ||
    lower.includes('spesial')
  ) {
    return 'Menu best-seller nomor satu di Bun Atelier adalah OG Main Character (Rp 72.000) dengan double smashed Australian beef patty juicy, double cheddar lumer, caramelized onions, dan secret relish sauce. Pilihan ayam renyah favorit kami adalah Crunch Culture (Rp 59.000). Untuk sides, Truffle Mac n Cheese (Rp 38.000) atau Rosemary Fries (Rp 28.000) jadi pasangan terbaik!';
  }

  // 10. OUTLET / CABANG / JAM BUKA
  if (
    lower.includes('outlet') ||
    lower.includes('lokasi') ||
    lower.includes('cabang') ||
    lower.includes('alamat') ||
    lower.includes('buka') ||
    lower.includes('toko') ||
    lower.includes('jam')
  ) {
    return 'Saat ini Bun Atelier memiliki 2 outlet resmi:\n1. Senopati Flagship: Jl. Senopati No. 45, Kebayoran Baru, Jakarta Selatan (Buka: 10:00 - 23:00 WIB)\n2. PIK 2 Waterfront: Pantai Indah Kapuk 2, Boulevard Raya No. 12, Jakarta Utara (Buka: 11:00 - 00:00 WIB)\nKeduanya buka setiap hari Senin - Minggu termasuk hari libur nasional!';
  }

  // 11. HARGA MENU / BERAPAAN
  if (
    lower.includes('harga') ||
    lower.includes('berapa') ||
    lower.includes('pricelist') ||
    lower.includes('daftar harga')
  ) {
    return 'Daftar harga menu di Bun Atelier:\n• Burger Utama: Rp 58.000 - Rp 85.000 (Paling murah: Touch Grass Rp 58.000 | Paling mahal: Truffle Butter Truce Rp 85.000)\n• Croissant Burger: Rp 66.000 - Rp 76.000\n• Side Quest: Rp 22.000 - Rp 48.000\n• Drinks: Rp 15.000 - Rp 35.000\n• Desserts: Rp 26.000 - Rp 42.000\nSemua harga transparan dan nett tanpa biaya tersembunyi!';
  }

  // 12. CARA PESAN / PENGIRIMAN
  if (
    lower.includes('pesan') ||
    lower.includes('order') ||
    lower.includes('antar') ||
    lower.includes('kirim') ||
    lower.includes('delivery') ||
    lower.includes('bayar')
  ) {
    return 'Kamu bisa langsung memilih menu favorit di aplikasi Bun Atelier ini dan melakukan checkout. Metode pembayaran yang didukung meliputi E-Wallet (GoPay, OVO, DANA), Transfer Bank, Kartu Kredit/Debit, dan Bayar di Tempat (COD). Estimasi pengiriman 30-60 menit.';
  }

  // 13. DYNAMIC CONVERSATIONAL FALLBACK
  const cleanTopic = userMessage.length > 40 ? userMessage.substring(0, 40) + '...' : userMessage;
  return `Halo! Terkait pertanyaanmu tentang "${cleanTopic}", Bun Atelier menyediakan burger artisanal berkualitas tinggi seperti burger termahal Truffle Butter Truce (Rp 85.000), best-seller OG Main Character (Rp 72.000), aneka Croissant Burger, cemilan Sides gurih, serta Desserts lezat.\n\nAda yang ingin kamu tanyakan lebih spesifik seputar rasa burger, rekomendasi paket, atau outlet kami?`;
}

class GeminiService {
  private aiClient: GoogleGenAI | null = null;
  private lastApiKey: string = '';

  private getApiKey(): string {
    try {
      const __filename = fileURLToPath(import.meta.url);
      const __dirname = path.dirname(__filename);
      const envPath = path.resolve(__dirname, '../../.env');
      if (fs.existsSync(envPath)) {
        dotenv.config({ path: envPath, override: true });
      }
    } catch {
      // ignore
    }
    const currentKey = process.env.GEMINI_API_KEY || config.geminiApiKey;
    return currentKey?.trim() ?? '';
  }

  private getClient(): GoogleGenAI | null {
    const cleanKey = this.getApiKey();

    if (cleanKey.length > 10 && !cleanKey.includes('YOUR_GEMINI_API_KEY')) {
      if (!this.aiClient || this.lastApiKey !== cleanKey) {
        this.aiClient = new GoogleGenAI({ apiKey: cleanKey });
        this.lastApiKey = cleanKey;
      }
      return this.aiClient;
    }

    return null;
  }

  public isConfigured(): boolean {
    const cleanKey = this.getApiKey();
    return cleanKey.length > 10 && !cleanKey.includes('YOUR_GEMINI_API_KEY');
  }

  public async generateSupportReply(
    userMessage: string,
    history: ChatHistoryItem[] = [],
    currencyContext?: CurrencyContextPayload
  ): Promise<string> {
    const client = this.getClient();
    if (!client) {
      // If API key is missing, provide fallback immediately so user never encounters an error
      return cleanAsterisks(getSmartConciergeReply(userMessage, currencyContext));
    }

    let dynamicSystemInstruction = SYSTEM_INSTRUCTION;
    if (currencyContext) {
      dynamicSystemInstruction += `\n\n7. INFORMASI RESMI KONVERSI MATA UANG GLOBAL (GROUND TRUTH RESMI DARI SISTEM APLIKASI):
DILARANG MENGARANG ANGKA HARGA / KURS!
Gunakan HANYA fakta numerik berikut yang sudah dihitung secara presisi dari sistem aplikasi:
- Tipe Permintaan: ${currencyContext.queryType || '-'}
${currencyContext.productName ? `- Nama Produk: ${currencyContext.productName}` : ''}
${currencyContext.originalPriceIdr ? `- Harga Asli Produk: Rp ${currencyContext.originalPriceIdr.toLocaleString('id-ID')}` : ''}
${currencyContext.searchedTerm ? `- Produk yang Dicari Pelanggan: "${currencyContext.searchedTerm}" (TIDAK DITEMUKAN di menu resmi)` : ''}
${currencyContext.cartGrandTotalIdr ? `- Total Aktual Keranjang / Checkout: Rp ${currencyContext.cartGrandTotalIdr.toLocaleString('id-ID')} (${currencyContext.cartItemCount} item)` : ''}
${currencyContext.targetCurrency ? `- Mata Uang Tujuan: ${currencyContext.targetCurrency}` : ''}
${currencyContext.formattedConverted ? `- Nilai Konversi Aktual: ${currencyContext.formattedConverted}` : ''}
${currencyContext.rateInfoText ? `- Keterangan Kurs: ${currencyContext.rateInfoText}` : ''}

Panduan Merespons Konversi Mata Uang:
1. Jika pertanyaan diajukan dalam Bahasa Inggris, jawablah dalam Bahasa Inggris yang elegan dan natural. Jika dalam Bahasa Indonesia, jawab dalam Bahasa Indonesia yang ramah.
2. JANGAN PERNAH gunakan tanda bintang atau asterisk (* atau **) sama sekali.
3. Sebutkan harga produk asli atau total keranjang dalam IDR, lalu sebutkan perkiraan nilainya dalam mata uang tujuan secara akurat sesuai angka di atas.
4. SELALU tegaskan kalimat penutup: pembayaran akhir pesanan tetap dalam IDR (Rupiah) / "The final payment remains in IDR."
5. Jika tipe adalah 'product_not_found', jelaskan bahwa produk tersebut belum tersedia di menu Bun Atelier saat ini, lalu rekomendasikan burger yang ada seperti OG Main Character, Smash Hit, Hot Mess Express, atau Truffle Butter Truce.
6. Jika tipe adalah 'cart_empty', beri tahu bahwa keranjang belanja masih kosong dengan ramah.`;
    }

    const contents = buildAlternatingContents(history, userMessage);

    let timeoutId: ReturnType<typeof setTimeout>;
    const timeoutPromise = new Promise<never>((_, reject) => {
      timeoutId = setTimeout(() => {
        reject(
          new Error(
            `Gemini API request timed out after ${config.requestTimeoutMs}ms`
          )
        );
      }, config.requestTimeoutMs || 30000);
    });

    const apiPromise = (async () => {
      // Model Gemini resmi yang aktif dan berkecepatan tinggi
      const modelsToTry = [
        'gemini-3.5-flash-lite',
        'gemini-3.5-flash',
        'gemini-3.8-flash',
        'gemini-3.1-flash-lite',
      ];
      let lastError: unknown = null;

      for (const model of modelsToTry) {
        try {
          const response = await client.models.generateContent({
            model,
            contents,
            config: {
              systemInstruction: dynamicSystemInstruction,
              temperature: 0.7,
              maxOutputTokens: 600,
            },
          });
          const reply = response.text?.trim();
          if (reply) {
            return cleanAsterisks(reply);
          }
          lastError = new Error('Gemini returned an empty response.');
        } catch (error) {
          lastError = error;
          const details =
            error instanceof Error ? error.message : String(error);
          console.warn(`Gemini model ${model} failed: ${details}`);
        }
      }

      throw lastError ?? new Error('No response from Gemini API.');
    })();

    try {
      return await Promise.race([apiPromise, timeoutPromise]);
    } catch (err) {
      console.warn('All Gemini models failed or timed out. Falling back to 24/7 Concierge engine:', err);
      // Guarantee 24/7 response so the mobile user NEVER sees connection failure
      return cleanAsterisks(getSmartConciergeReply(userMessage, currencyContext));
    } finally {
      clearTimeout(timeoutId!);
    }
  }
}

export const geminiService = new GeminiService();
