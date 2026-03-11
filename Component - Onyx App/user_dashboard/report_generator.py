from datetime import datetime
from memory.vector_memory import store_learning_chunk

def generate_report(client_name="Demo Client"):
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    report = {
        "client": client_name,
        "timestamp": now,
        "monthly_revenue": "$8,400",
        "expenses": "$4,900",
        "net_profit": "$3,500",
        "kpi": {
            "client_growth": "11%",
            "retention": "97%",
            "ai-automation": "84%"
        },
        "status": "🟢 Healthy"
    }

    # Store summary in memory
    store_learning_chunk(
        source="Onyx Report",
        summary=f"Report for {client_name} generated at {now}. Status: {report['status']}"
    )

    return report
