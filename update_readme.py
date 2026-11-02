Sicherheitsrichtlinie (Security Policy)
Vielen Dank, dass Sie zur Sicherheit von Sky OS – Das Framework beitragen. Da dieses System auf absolute Datensouveränität und lokale Ausführung ausgelegt ist, nehmen wir Sicherheit sehr ernst.

🛡️ Unterstützte Versionen
Da sich Sky OS in der aktiven Entwicklung befindet, wird Support und Sicherheitsupdates primär für den main-Branch bereitgestellt.

Version	Unterstützt
4.x	✅ Ja
< 4.0	❌ Nein
🚨 Meldung einer Sicherheitslücke (Vulnerability)
Wenn Sie eine Sicherheitslücke entdecken, möchten wir sicherstellen, dass sie verantwortungsvoll behoben werden kann, bevor sie öffentlich wird.

Bitte erstellen Sie KEINE öffentlichen GitHub-Issues für sicherheitsrelevante Funde.
Melten Sie Sicherheitslücken stattdessen direkt über einen privaten Kommunikationskanal oder per E-Mail an den Repository-Maintainer.
Bitte fügen Sie eine detaillierte Beschreibung des Problems, Schritte zur Reproduktion sowie mögliche Lösungsvorschläge bei.
🔒 Lokales Sicherheitsmodell
Keine Cloud-Abhängigkeit: Sky OS läuft lokal auf Ihrer Hardware (z. B. Lenovo ThinkPad unter WSL). Sensible Daten und das quantensichere Ledger (audit_quantum_ledger.json) bleiben isoliert auf Ihrem System.
Kryptografische Integrität: Alle Systemereignisse und Transaktionen werden über SHA3-256 Hash-Ketten mathematisch versiegelt.
