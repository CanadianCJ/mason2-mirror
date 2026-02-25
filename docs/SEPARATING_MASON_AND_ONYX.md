\# Separating Mason and Onyx (For Sale / Handover)



Goal:  

\- You keep \*\*Mason\*\* as your private brain.  

\- Buyer/client gets \*\*Onyx\*\* as a clean, stand-alone product that does not depend on Mason.



This guide is for the future when you want to:

\- Sell Onyx outright, or

\- Deploy Onyx for a client without exposing Mason.



---



\## 1. Know which copy is which



On this PC right now:



\- \*\*Mason root\*\*  

&nbsp; `C:\\Users\\Chris\\Desktop\\Mason2`



\- \*\*Your internal Onyx (dev copy)\*\*  

&nbsp; `C:\\Users\\Chris\\Desktop\\Onyx\\onyx\_business\_manager`



This internal Onyx:

\- Can stay connected to Mason for auto-improvements.

\- Is for \*\*you\*\*, not for clients.



When you sell or deploy, you will make a \*\*clean client copy\*\* of Onyx.



---



\## 2. What “separation” really means



When you separate Onyx from Mason for a sale or client:



\- Onyx must:

&nbsp; - Run on its own (no need for Mason folders or scripts),

&nbsp; - Talk only to its own backend / database,

&nbsp; - Have standard install/run docs.



\- Mason must:

&nbsp; - Stop touching that client’s Onyx directly,

&nbsp; - Keep working only on \*\*your\*\* internal copy (if you want).



You are basically saying:

> “Mason is my internal R\&D. Clients only get the product outputs, not Mason himself.”



---



\## 3. Create a clean client copy of Onyx



When you’re ready to hand Onyx to someone:



1\. Decide a client folder, for example:



&nbsp;  - `C:\\Clients\\OnyxClientA\\onyx\_business\_manager`



2\. Copy your dev project into it:



&nbsp;  - From:  

&nbsp;    `C:\\Users\\Chris\\Desktop\\Onyx\\onyx\_business\_manager`

&nbsp;  - To:  

&nbsp;    `C:\\Clients\\OnyxClientA\\onyx\_business\_manager`



3\. In that client copy:

&nbsp;  - Remove any dev-only notes or experimental files you don’t want to ship.

&nbsp;  - Make sure any config files point to:

&nbsp;    - The \*\*client’s\*\* backend / database,

&nbsp;    - \*\*Not\*\* to local Mason paths or ports.



Right now Mason lives entirely under `C:\\Users\\Chris\\Desktop\\Mason2`, so the Onyx project itself is mostly clean already.



---



\## 4. Make sure Mason ignores the client copy



Mason’s autonomy and planning rules live in:



\- `C:\\Users\\Chris\\Desktop\\Mason2\\policies\\Mason\_AutonomyPolicy.json`



To keep Mason from touching a client’s Onyx directly:



\- Only point Mason’s tools at \*\*your\*\* internal Onyx path.

\- Do \*\*not\*\* configure any tools or tasks that write into the client’s project folder or servers.



If in the future we ever add explicit paths or configs for “Onyx targets”, this section is where we will list what to change.



Simple rule for future you:



> Internal Onyx path = OK for Mason.  

> Client Onyx paths = read-only or completely ignored.



---



\## 5. Test Onyx without Mason



Before giving Onyx to anyone, test that it works alone.



On a test machine or a fresh Windows user:



1\. Install whatever Onyx needs (Flutter, runtime, backend, or a packaged installer).

2\. Copy only the \*\*client\*\* Onyx folder there.

3\. Run Onyx:

&nbsp;  - Using the documented startup command or packaged EXE.

4\. Confirm:

&nbsp;  - App launches.

&nbsp;  - Basic CRM flows work (contacts, deals, tasks, invoices).

&nbsp;  - No errors about Mason paths (no references to `C:\\Users\\Chris\\Desktop\\Mason2`).



If it runs fine in that environment, Onyx is properly separated.



---



\## 6. What you actually hand over



To a buyer/client you normally provide:



\- Onyx source code or build:

&nbsp; - The clean `onyx\_business\_manager` project, or

&nbsp; - A packaged binary + backend.

\- Simple docs:

&nbsp; - “How to install”

&nbsp; - “How to run”

&nbsp; - “Basic usage”



You \*\*do not\*\* provide:



\- `C:\\Users\\Chris\\Desktop\\Mason2` (Mason’s folders, tools, logs),

\- Mason autonomy policies,

\- Internal Mason reports and tasks.



Mason stays with you as your “mega brain” for:



\- Your own Onyx,

\- Future apps,

\- Your smart home / bigger Mason house vision.



---



\## 7. After the sale or deployment



If you keep Onyx as your own product:



\- Continue letting Mason improve \*\*your\*\* internal Onyx copy.

\- Promote improvements the normal way:

&nbsp; - New releases / updates you send to clients.



If you fully sell Onyx and walk away:



\- Archive your internal Onyx copy (for your records).

\- Decide what Mason should focus on next:

&nbsp; - Other apps,

&nbsp; - Your PC/security,

&nbsp; - Smart home, etc.



---



\## 8. Quick checklist for “Is Onyx safe to hand over?”



Before you give Onyx to someone, ask:



\- \[ ] Does Onyx run on a clean machine without Mason installed?

\- \[ ] Are all configs pointing to the right backend (not to local experiments)?

\- \[ ] Does the project contain \*\*no\*\* references to `C:\\Users\\Chris\\Desktop\\Mason2`?

\- \[ ] Do I have my own internal copy still wired to Mason (if I want Mason to keep improving it)?



If all boxes are checked, Onyx is safe to sell or deploy without exposing Mason.



