(function () {
  var devicesEl = document.getElementById("tuiDevices");
  var logEl = document.getElementById("tuiLog");
  var lagEl = document.getElementById("tuiLag");
  var jitEl = document.getElementById("tuiJitter");

  var DEVICES = [
    { ip: "192.168.1.1", label: "ROUTER", base: 2, var: 3 },
    { ip: "192.168.1.5", label: "YOUR PC", base: 9, var: 6 },
    { ip: "192.168.1.9", label: "TV", base: 84, var: 30 },
    { ip: "192.168.1.12", label: "PHONE", base: 24, var: 16 },
    { ip: "192.168.1.23", label: "MIBOX4", base: 47, var: 55 },
    { ip: "192.168.1.33", label: "LAPTOP", base: 11, var: 7 }
  ];

  function pingClass(ms) {
    if (ms < 30) return "ok";
    if (ms < 80) return "warn";
    return "bad";
  }

  var rows = [];
  var pings = DEVICES.map(function (d) { return d.base; });

  if (devicesEl) {
    DEVICES.forEach(function (d, i) {
      var row = document.createElement("div");
      row.className = "tui-row";
      var ip = document.createElement("span");
      ip.className = "c-ip";
      ip.textContent = d.ip;
      var lab = document.createElement("span");
      lab.className = "c-label";
      lab.textContent = d.label;
      var ping = document.createElement("span");
      ping.className = "c-ping ok";
      ping.textContent = pings[i] + "ms";
      row.appendChild(ip); row.appendChild(lab); row.appendChild(ping);
      devicesEl.appendChild(row);
      rows.push({ row: row, ping: ping, cfg: d });
    });
  }

  setInterval(function () {
    for (var i = 0; i < rows.length; i++) {
      var v = pings[i] + (Math.random() * rows[i].cfg.var * 2 - rows[i].cfg.var);
      v = Math.max(1, Math.round(v));
      pings[i] = v;
      rows[i].ping.textContent = v + "ms";
      rows[i].ping.className = "c-ping " + pingClass(v);
    }
  }, 1600);

  var LOG_LINES = [
    "[+] GNULTE v8.0 initialized",
    "[+] Scanning 192.168.1.0/24 ... done",
    "[+] Found 8 devices \u2014 3 phones, 2 TVs, 1 printer",
    "[*] Verifying target reachability ... 192.168.1.23: ok",
    "[*] Disclaimers accepted. It keeps asking anyway.",
    "[+] Enabling IP forwarding ... done",
    "[*] arpspoof armed: 192.168.1.23 \u21c4 192.168.1.1",
    "[+] tc netem applied: delay 2000ms \u00b1 500ms jitter",
    "[+] LATENCY ACTIVE \u2014 dashboard pinging every second",
    "[+] Spoof watcher healed a sleeping arpspoof",
    "[*] Report: gnulte-report/report.html (+svg graphs)",
    "[+] Cleanup complete \u2014 qdisc removed, forwarding off",
    "[*] Device 192.168.1.9 reconnecting ... again",
    "[+] Auto-restarting monitor window ... calm down"
  ];

  function logLine(text, cls) {
    if (!logEl) return;
    var line = document.createElement("div");
    line.className = "lg " + (cls || "");
    line.textContent = text;
    logEl.appendChild(line);
    while (logEl.childNodes.length > 8) logEl.removeChild(logEl.firstChild);
    logEl.scrollTop = logEl.scrollHeight;
  }

  var li = 0;
  function logLoop() {
    var l = LOG_LINES[li % LOG_LINES.length];
    var cls = "";
    if (l.indexOf("LATENCY ACTIVE") !== -1) cls = "lg-cyan";
    else if (l.indexOf("[+]") === 0) cls = "lg-green";
    else if (l.indexOf("[*]") === 0 && l.indexOf("Report") !== -1) cls = "lg-amber";
    logLine(l, cls);
    li++;
    setTimeout(logLoop, 2100 + Math.random() * 1800);
  }
  setTimeout(logLoop, 1400);

  if (lagEl) {
    var base = 2000;
    setInterval(function () {
      base = [500, 1000, 2000, 3000, 5000][Math.floor(Math.random() * 5)];
      lagEl.textContent = base + "ms";
      if (jitEl) jitEl.textContent = (base / 4) + "ms";
    }, 4600);
  }

  /* ---- scroll reveal ---- */
  var revealIO = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (e.isIntersecting) {
        e.target.classList.add("in");
        revealIO.unobserve(e.target);
      }
    });
  }, { threshold: 0.12 });
  document.querySelectorAll(".reveal").forEach(function (el, i) {
    el.style.setProperty("--d", String((i % 4) * 0.07) + "s");
    revealIO.observe(el);
  });
})();