.pragma library

function has(v) { return v !== undefined && v !== null && !(typeof v === "number" && isNaN(v)); }
function num(v, def) { return has(v) ? Number(v) : (def === undefined ? 0 : def); }
function fix(v, dec, dash) { return has(v) ? Number(v).toFixed(dec) : (dash === undefined ? "--" : dash); }
function str(v, dash) { return has(v) && String(v).length > 0 ? String(v) : (dash === undefined ? "—" : dash); }
function sign(v, dec) { if (!has(v)) return "--"; var s = Number(v).toFixed(dec); if (Number(s) === 0) return Number(0).toFixed(dec); return Number(v) > 0 ? "+" + s : s; }

// 距離 (m) の表示: 1000m 以上は km
function dist(m) {
    if (!has(m)) return "—";
    var a = Math.abs(m);
    if (a >= 1000) return (m / 1000).toFixed(2) + " km";
    if (a >= 100) return Math.round(m) + " m";
    return Number(m).toFixed(1) + " m";
}
function distNum(m) {
    if (!has(m)) return "---";
    var a = Math.abs(m);
    if (a >= 1000) return (m / 1000).toFixed(2);
    if (a >= 100) return String(Math.round(m));
    return Number(m).toFixed(1);
}
function distUnit(m) { return has(m) && Math.abs(m) >= 1000 ? "km" : "m"; }

// ノッチ名: P1..Pn / N / B1..Bn / EB (b が maxB を超えたら非常)
function notchName(n) {
    if (!n) return "--";
    if (n.b > n.maxB) return "EB";
    if (n.b > 0) return "B" + n.b;
    if (n.p > 0) return "P" + n.p;
    return "N";
}
function revName(r) { return r === 1 ? "前" : r === -1 ? "後" : r === 0 ? "切" : "—"; }
function pad2(n) { return (n < 10 ? "0" : "") + n; }
