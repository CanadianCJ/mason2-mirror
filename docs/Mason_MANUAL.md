\# Mason – Owner Manual



\_Last updated: (update this line when we change things)\_



\## What Mason is



Mason is the “brain” running on this PC.  

He lives in this folder:



\- `C:\\Users\\Chris\\Desktop\\Mason2`



Mason’s jobs:



\- Watch his own health and your PC’s health.

\- Watch Onyx and Athena.

\- Create tasks to improve everything over time.

\- Respect autonomy levels and risk rules (he has to “earn” higher levels).



Mason is \*\*secret\*\*. Onyx clients don’t see him. He is your private operator.



---



\## Important folders



Inside `C:\\Users\\Chris\\Desktop\\Mason2`:



\- `tools\\`  

&nbsp; PowerShell scripts that run checks, reports, and helpers.

\- `policies\\`  

&nbsp; Rules about what Mason is allowed to touch (`Mason\_AutonomyPolicy.json`).

\- `reports\\`  

&nbsp; JSON reports Mason makes about himself, Onyx, and the PC.

\- `tasks\\pending\\onyx\\`  

&nbsp; To-do files for fixing Onyx (created from analyzer output).

\- `docs\\`  

&nbsp; Manuals and status files (this file is here).



There may also be a `logs\\` folder where different tools write log files.



---



\## How to run Mason’s main tools by hand



1\. Open \*\*Windows PowerShell\*\*.

2\. Go to Mason’s tools folder:



&nbsp;  ```powershell

&nbsp;  cd "C:\\Users\\Chris\\Desktop\\Mason2\\tools"



