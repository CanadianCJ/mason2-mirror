from datetime import datetime, timedelta

def generate_report(period: str = "last_7_days", fmt: str = "json"):
    now = datetime.utcnow()
    if period == "last_30_days":
        start = now - timedelta(days=30)
    else:
        start = now - timedelta(days=7)

    data = {
        "period": period,
        "start": start.isoformat() + "Z",
        "end": now.isoformat() + "Z",
        "summary": {
            "new_clients": 3,
            "active_projects": 2,
            "invoices_sent": 5,
            "revenue": 4210.00,
        },
    }
    if fmt == "text":
        return {
            "text": (
                f"Onyx report ({period}): "
                f"{data['summary']['new_clients']} new clients, "
                f"{data['summary']['active_projects']} active projects, "
                f"{data['summary']['invoices_sent']} invoices, "
                f"revenue ${data['summary']['revenue']:.2f}."
            )
        }
    return data
