import 'package:lucide_icons_flutter/lucide_icons.dart';

/// TAIFA icon system.
///
/// The app draws its glyphs from **Lucide** rather than Material: its even
/// 2px geometric strokes and open counters sit better with Playfair's
/// ceremony and the Sahara Emerald / Ceremonial Gold palette than Material's
/// utility shapes do, and the family is consistent enough that a screen full
/// of them reads as one system.
///
/// (Phosphor was the first choice — the design database's primary family —
/// but `phosphor_flutter` subclasses `IconData`, which Flutter 3.44 made a
/// `final class`, so it no longer compiles. Lucide is the named fallback
/// family and declares plain `IconData` constants.)
///
/// **Stroke/hierarchy discipline** (one style per hierarchy level):
/// Lucide is a single-weight outline family, so hierarchy comes from *size*
/// and *colour*, never from mixing filled and outline glyphs at the same
/// level. Active nav state is carried by the gold gradient pill plus a bolder
/// label, not by swapping in a filled glyph.
///
/// Never reach for `LucideIcons.*` directly in feature code: add a semantic
/// name here so the vocabulary stays searchable and swappable in one place.
class TaifaIcons {
  const TaifaIcons._();

  // === Navigation shell ===
  static const home = LucideIcons.house;
  static const mobility = LucideIcons.compass;
  static const ai = LucideIcons.sparkles;
  static const wallet = LucideIcons.wallet;
  static const menu = LucideIcons.menu;

  // === Chrome / structural ===
  static const back = LucideIcons.arrowLeft;
  static const forward = LucideIcons.arrowRight;
  static const close = LucideIcons.x;
  static const chevronRight = LucideIcons.chevronRight;
  static const chevronDown = LucideIcons.chevronDown;
  static const search = LucideIcons.search;
  static const filter = LucideIcons.slidersHorizontal;
  static const refresh = LucideIcons.refreshCw;
  static const add = LucideIcons.plus;
  static const addCircle = LucideIcons.circlePlus;
  static const remove = LucideIcons.circleMinus;
  static const delete = LucideIcons.trash2;
  static const edit = LucideIcons.pencil;
  static const copy = LucideIcons.copy;
  static const share = LucideIcons.share2;
  static const settings = LucideIcons.settings;
  static const info = LucideIcons.info;
  static const help = LucideIcons.circleHelp;
  static const lightMode = LucideIcons.sun;
  static const darkMode = LucideIcons.moon;
  static const microphone = LucideIcons.mic;
  static const camera = LucideIcons.camera;
  static const upload = LucideIcons.upload;
  static const download = LucideIcons.download;
  static const attachment = LucideIcons.paperclip;
  static const location = LucideIcons.mapPin;
  static const calendar = LucideIcons.calendar;
  static const clock = LucideIcons.clock;
  static const phone = LucideIcons.phone;
  static const mail = LucideIcons.mail;
  static const user = LucideIcons.user;
  static const users = LucideIcons.users;
  static const lock = LucideIcons.lock;
  static const logout = LucideIcons.logOut;
  static const visible = LucideIcons.eye;
  static const hidden = LucideIcons.eyeOff;
  static const star = LucideIcons.star;
  static const heart = LucideIcons.heart;
  static const flag = LucideIcons.flag;
  static const pin = LucideIcons.pin;
  static const link = LucideIcons.link;
  static const document = LucideIcons.fileText;
  static const folder = LucideIcons.folder;
  static const image = LucideIcons.image;
  static const chat = LucideIcons.messageCircle;
  static const send = LucideIcons.send;

  // === Status / feedback ===
  static const success = LucideIcons.circleCheck;
  static const error = LucideIcons.circleX;
  static const warning = LucideIcons.triangleAlert;
  static const pending = LucideIcons.hourglass;
  static const check = LucideIcons.check;
  static const shield = LucideIcons.shieldCheck;

  // === Money: core wallet ===
  static const sendMoney = LucideIcons.arrowUpRight;
  static const receiveMoney = LucideIcons.arrowDownLeft;
  static const topUp = LucideIcons.circlePlus;
  static const withdraw = LucideIcons.arrowDownToLine;
  static const scanQr = LucideIcons.scanLine;
  static const card = LucideIcons.creditCard;
  static const bank = LucideIcons.landmark;
  static const coins = LucideIcons.coins;
  static const receipt = LucideIcons.receipt;
  static const history = LucideIcons.history;
  static const analytics = LucideIcons.chartLine;
  static const refund = LucideIcons.undo2;

  // === Money: social payments ===
  static const paymentLink = LucideIcons.link2;
  static const moneyRequest = LucideIcons.handCoins;
  static const splitBill = LucideIcons.receiptText;
  static const standingOrder = LucideIcons.repeat;
  static const contacts = LucideIcons.contact;
  static const notifications = LucideIcons.bell;
  static const spendingCap = LucideIcons.shieldCheck;
  static const merchant = LucideIcons.store;
  static const qrCode = LucideIcons.qrCode;

  // === Super-app domains ===
  static const ride = LucideIcons.car;
  static const transit = LucideIcons.bus;
  static const delivery = LucideIcons.truck;
  static const food = LucideIcons.utensils;
  static const shopping = LucideIcons.shoppingBag;
  static const cart = LucideIcons.shoppingCart;
  static const hotel = LucideIcons.bed;
  static const flight = LucideIcons.plane;
  static const tourism = LucideIcons.compass;
  static const government = LucideIcons.building2;
  static const health = LucideIcons.heartPulse;
  static const education = LucideIcons.graduationCap;
  static const jobs = LucideIcons.briefcase;
  static const housing = LucideIcons.house;
  static const insurance = LucideIcons.umbrella;
  static const agriculture = LucideIcons.sprout;
  static const wealth = LucideIcons.trendingUp;
  static const family = LucideIcons.users;
  static const nfc = LucideIcons.wifi;
  static const sos = LucideIcons.siren;
  static const ops = LucideIcons.gauge;
  static const globe = LucideIcons.globe;
  static const building = LucideIcons.building2;
  static const ticket = LucideIcons.ticket;
  static const route = LucideIcons.route;
}

/// Icon sizing tokens. Ad-hoc pixel values are what made the previous pass
/// look uneven (9px through 96px with no rhythm) — stick to these.
class TaifaIconSize {
  const TaifaIconSize._();

  /// Inline with dense body text / chips.
  static const double sm = 16;

  /// Default UI glyph: list affordances, nav, buttons.
  static const double md = 20;

  /// Prominent actions, section headers.
  static const double lg = 24;

  /// Feature tiles.
  static const double xl = 32;

  /// Empty-state and hero art.
  static const double hero = 48;
}
