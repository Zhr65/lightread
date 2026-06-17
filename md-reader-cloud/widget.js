// ============================================
// 轻读 · Scriptable 小组件 v2
// ============================================

const SUPABASE_URL = "https://nctkutjmjyvccnnwzddt.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5jdGt1dGptanl2Y2Nubnd6ZGR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2NDE1MTEsImV4cCI6MjA5NzIxNzUxMX0.hCylCiO0pdkW9vsRB8kw6tBUL1FlVPxz_qO5yXOaqVw";

const QUOTES = [
  "夜色难免黑凉，前行必有曙光。",
  "星光不问赶路人，时光不负有心人。",
  "最清晰的脚印，踩在最泥泞的路上。",
  "没有一朵花，从一开始就是花。",
  "跨过去的都是门，跨不过去的才是坎。",
  "你可以很努力，但不用太着急。",
  "追光的人，终会光芒万丈。",
  "时间从来不语，却回答了所有问题。"
];

async function fetchCountdowns() {
  const url = SUPABASE_URL + "/rest/v1/countdowns?select=*&order=target_date.asc";
  const req = new Request(url);
  req.method = "GET";
  req.headers = {
    "apikey": SUPABASE_KEY,
    "Authorization": "Bearer " + SUPABASE_KEY,
    "Content-Type": "application/json"
  };
  const data = await req.loadJSON();
  return Array.isArray(data) ? data : [];
}

function calcDays(targetDate, repeatYearly) {
  const now = new Date(); now.setHours(0,0,0,0);
  let target = new Date(targetDate + "T00:00:00");
  if (repeatYearly) {
    target.setFullYear(now.getFullYear());
    if (target < now) target.setFullYear(now.getFullYear() + 1);
  }
  return Math.ceil((target - now) / 86400000);
}

async function run() {
  const widget = new ListWidget();

  // 背景
  const gradient = new LinearGradient();
  gradient.colors = [new Color("#0ea5e9"), new Color("#38bdf8")];
  gradient.locations = [0, 1];
  widget.backgroundGradient = gradient;
  widget.setPadding(14, 14, 14, 14);

  try {
    const countdowns = await fetchCountdowns();

    const sorted = countdowns
      .map(c => ({ ...c, remaining: calcDays(c.target_date, c.repeat_yearly) }))
      .sort((a, b) => a.remaining - b.remaining)
      .filter(c => c.remaining >= -1);

    // 标题
    const title = widget.addText("📅 倒数日");
    title.font = Font.boldSystemFont(13);
    title.textColor = Color.white();
    title.textOpacity = 0.9;
    widget.addSpacer(8);

    if (sorted.length === 0) {
      const empty = widget.addText("还没有倒数日");
      empty.font = Font.systemFont(12);
      empty.textColor = Color.white();
    } else {
      const wf = (typeof config !== "undefined" && config.widgetFamily) || "small";
      const maxShow = wf === "small" ? 2 : wf === "medium" ? 4 : 6;
      const toShow = sorted.slice(0, maxShow);

      for (const c of toShow) {
        const row = widget.addStack();
        row.layoutHorizontally();
        row.spacing = 6;
        row.centerAlignContent();

        const daysText = row.addText(c.remaining === 0 ? "今" : String(c.remaining));
        daysText.font = Font.boldSystemFont(11);
        daysText.textColor = Color.white();
        daysText.minimumScaleFactor = 0.6;

        const nameText = row.addText(c.title);
        nameText.font = Font.systemFont(11);
        nameText.textColor = Color.white();
        nameText.lineLimit = 1;

        row.addSpacer();

        const dateText = row.addText(String(c.target_date).slice(5));
        dateText.font = Font.systemFont(8);
        dateText.textColor = Color.white();
        dateText.textOpacity = 0.7;

        widget.addSpacer(3);
      }
    }

    widget.addSpacer(6);

    // 分隔线
    const sep = widget.addText("─".repeat(16));
    sep.font = Font.systemFont(6);
    sep.textColor = Color.white();
    sep.textOpacity = 0.3;
    widget.addSpacer(4);

    // 每日金句
    const quote = QUOTES[Math.floor(Date.now() / 86400000) % QUOTES.length];
    const qText = widget.addText(quote);
    qText.font = Font.italicSystemFont(9);
    qText.textColor = Color.white();
    qText.textOpacity = 0.85;
    qText.lineLimit = 2;

    const src = widget.addText("—— 人民日报");
    src.font = Font.systemFont(7);
    src.textColor = Color.white();
    src.textOpacity = 0.5;

  } catch (e) {
    const err = widget.addText("📡 无法连接");
    err.font = Font.systemFont(12);
    err.textColor = Color.white();
    const detail = widget.addText("请检查网络后重试");
    detail.font = Font.systemFont(8);
    detail.textColor = Color.white();
    detail.textOpacity = 0.6;
  }

  return widget;
}

const w = await run();
if (config.runsInWidget) {
  Script.setWidget(w);
} else {
  await w.presentSmall();
}
Script.complete();
