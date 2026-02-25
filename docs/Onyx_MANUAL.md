# Onyx – Owner Manual

_Last updated: (update this line when we change things)_

## What Onyx is

Onyx is the **business manager app** – the “face” your users see.

It is meant to handle things like:

- Contacts & companies  
- Deals / jobs  
- Tasks & reminders  
- Invoices & statuses (draft / sent / paid / overdue)  
- Dashboards and workflows (as they grow)  

Mason is the brain. Onyx is the interface.

---

## Where Onyx lives (this machine)

Main project folder:

- `C:\Users\Chris\Desktop\Onyx\onyx_business_manager`

That folder contains:

- Flutter/Dart code for the app  
- Screens for founders, tasks, invoices, etc.  
- Config for how it talks to the backend (now and in the future)

---

## Basic “how to run” (dev mode)

Right now you’ll usually run Onyx in **dev mode** from that folder.

Typical flow (we will refine this later):

1. Open your editor (VS Code / other).
2. Open the folder:  
   `C:\Users\Chris\Desktop\Onyx\onyx_business_manager`
3. Run the Flutter app (from the editor or from a terminal).

When we lock in the exact start commands for your setup (e.g., `flutter run` or a packaged EXE), we’ll write them here.

---

## How Onyx connects to Mason (current state)

Important: Onyx does **not** have Mason “inside” it.

Instead:

- Mason lives in `C:\Users\Chris\Desktop\Mason2`
- Mason:
  - Reads health / analyzer output about Onyx  
  - Creates **task files** to fix things
- Onyx itself is still a normal app that can run without Mason.

So:

- You can run Onyx alone.  
- Mason just helps your copy get better over time.

---

## Onyx fix tasks (how Mason plans improvements)

Mason turns analyzer output into small “to-do” JSON files for Onyx.

Flow:

1. Mason (or you) run the analyzer and brain-context tools (already set up).
2. You run this from the tools folder:

   ```powershell
   cd "C:\Users\Chris\Desktop\Mason2\tools"
   .\Mason_Onyx_Analyzer_To_Tasks.ps1
