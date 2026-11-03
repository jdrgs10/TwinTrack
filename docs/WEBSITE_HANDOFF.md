# TwinTrack AI — Canonical Website Handoff

**Verified project snapshot: 6 October 2026.**

This is the portable factual and editorial brief for the separate TwinTrack website chat. The website already has a basic implementation. **Do not rebuild blindly: audit it first, preserve what is excellent, and improve what is weak.** This document supplies the project facts; access to the private iOS repository is not required to understand them.

This handoff is working material, not a page to publish verbatim. Sections explicitly labeled public copy can be used on the site. Operational notes, unresolved items and private-source references stay internal.

**Latest owner direction:** showcase the project. Do not add contribution breakdowns, personal-role claims, authorship disclosures or an AI-assisted-development section. Keep that material separate. Apple Foundation Models remains part of the product architecture and should be explained accurately.

## 1. Website objective and scope

Make the website the canonical public TwinTrack case study: suitable for a CV link, university application, technical interview, portfolio and graduation-project QR visitor.

A visitor should understand what exists, how it works, what was tested, what the research found and what remains unvalidated. The strongest story is a functioning native prototype with a clear numerical architecture and an honest evidence boundary.

This handoff authorizes no app/model changes, website implementation in the iOS chat, deployment, new domain, QR replacement or Canva redesign. The website chat should work within its own authorized project and publication workflow. Never infer permission to expose the private repository or internal evidence.

## 2. Current product: authoritative facts

| Area | Current fact |
| --- | --- |
| Product | Grade 12 graduation-project prototype; native Swift/SwiftUI iPhone app, with iPad layouts and selected simulator coverage. |
| Public description | **Digital-twin-inspired student reflection prototype.** Also defensible: **evidence-informed experimental prototype.** |
| Navigation | Exactly three primary tabs: **Home, TwinTrack AI, Profile**. |
| Academic model | **TwinTrack Ridge V2, version 2.0-final.1**, standardized Ridge Regression, **alpha = 0.1**. |
| Execution | Frozen numerical calculation implemented locally in Swift; deterministic for identical valid inputs and model version. |
| Training | V2 was developed with synthetic profiles. Real-student upcoming-score accuracy is unverified. |
| Output | Experimental assessment-score estimate, clamped to **0–100**. This bound is not a confidence interval or accuracy guarantee. |
| Target | Next scheduled, individually graded written quiz/test/exam in the selected subject, **1–7 local calendar days ahead**. |
| Previous result | Most recent comparable same-subject result, **1–90 local calendar days old**, normalized to a percentage. |
| Context | Subject, assessment identity/date and prior-result date/comparability are eligibility/provenance metadata, not additional Ridge features. |
| Missing/stale inputs | Prevent an eligible new calculation; unavailable data are not silently replaced with zero. A saved estimate stays historical. |
| Calculation/save | An explicit prediction action, including an authorized chat calculation, uses the shared calculation path. Merely rendering Home, refreshing inputs or opening history does not create a new estimate. |
| Conversation | Apple Foundation Models supports on-device conversation/explanation when runtime availability permits. App-owned tools/cards own authoritative numerical results. |
| Storage | Local saved estimates, manual entries and conversations; chat editing and user-initiated export are implemented. No app account or backend is part of this architecture. |
| Wellbeing | Experimental RHR trend and optional Body & Wellbeing/BMI are separate from academic prediction. |
| Release status | Latest automated gate passed. **Final physical acceptance is pending; feature/UI freeze is not declared.** |

### Exact seven-feature order

1. `sleep_hours` — sleep duration.
2. `steps` — step count.
3. `exercise_minutes` — Apple Exercise Time.
4. `resting_heart_rate` — resting heart rate.
5. `study_minutes` — selected-subject study outside class.
6. `screen_time_minutes` — recreational screen time.
7. `previous_score` — comparable previous assessment percentage.

The first four use accessible Apple Health/HealthKit readings. The final three are manual inputs. Educational screen use belongs to study, not recreational screen time. Neither BMI, date of birth, growth reference nor the RHR wellbeing trend is an eighth academic feature.

### Source windows and interpretation

- Sleep: yesterday's local noon through the earlier of now and today's local noon; combined asleep intervals, including naps.
- Steps and Exercise Time: previous completed local calendar day.
- RHR: latest valid positive sample within the previous 72 elapsed hours, retaining its timestamp.
- Study and recreational screens: previous local day; dated manual reports may require reconfirmation.
- These windows and the 1–7/1–90-day eligibility rules are product assumptions, **not empirically validated prediction horizons**.

Do not describe the inputs as a continuous live measurement of readiness. HealthKit is a read-only integration here; TwinTrack does not write synthetic or real readings back to Health.

## 3. Architecture the website should explain

Use one clear, responsive diagram with separate numerical and conversational paths:

```text
Apple Watch / compatible Health data sources
                    ↓
            Apple Health / HealthKit ──┐
                                      │
Manual academic inputs ────────────────┼→ Shared TwinTrack state
                                      │          ↓
Subject / assessment / date context ───┘  Eligibility and freshness checks
                                                 ↓
                                         Seven numerical features
                                                 ↓
                                    Frozen on-device Ridge V2
                                                 ↓
                                    Experimental assessment estimate
                                                 ↓
                                  Immutable saved result + source context

Captured eligible baseline → temporary What-If changes → same Ridge V2
                                                        ↓
                                              Baseline/scenario comparison

User request + permitted current or historical context
                    ↓
        App routing / read-only or calculation tools
                    ↓
     App-owned numerical cards + Foundation Models conversation

RHR history → experimental wellbeing trend ── separate from Ridge
Optional local body measurements → BMI ───── separate from Ridge
```

The wellbeing path may supply a permission-controlled read-only BMI summary to chat; it does not feed the academic model. Do not draw raw Health samples, profile photos or date of birth flowing freely into a language model.

**Deterministic:** Ridge inference, validated scenario arithmetic and app-calculated BMI. **Generative:** conversational prose from Foundation Models. **Local/on-device:** these app calculations, model sessions and app-owned stores. **Explicit sharing:** chat export lets the user choose a destination. Therefore “nothing can ever leave the device” is too broad.

No direct WHOOP integration, Fitbit API, Firebase backend, cloud Qwen service or browser prediction engine should appear as a current capability. A compatible source supplying Apple Health data is not evidence of a separate vendor integration.

## 4. Current app experience and boundaries

**Home:** compact assessment estimate, saved/current state distinction, input/source summaries, next-action guidance, refresh and expandable Details. Technical provenance and longer limitations belong in Details. The TwinTrack mark remains Home-only inside the app.

**TwinTrack AI:** compact chat header, conversation library, new chat, natural conversation, app-grounded reads/calculations and a compact Manual What-If entry. Saved chats can be renamed/deleted; user messages can be edited. Editing removes later turns before regenerating. Cancellation and chat-switch guards prevent late output entering another conversation. Live conversational quality still needs physical acceptance.

**Profile:** manual input access, appearance/profile-photo controls, Body & Wellbeing, Trends & History and Data & Privacy. The **blue Ridge Regression card is above the purple Apple Foundation Models card**. Do not remove the numerical/explanation distinction from screenshots or copy.

**History and trends:** stored estimates retain model/assessment/source identity. Current Trends & History supports **7/30-day views** of recorded information; missing dates remain gaps. Opening an old estimate or explaining it does not recalculate it as current. Do not imply continuous wearable capture or body-measurement history.

**What-If:** temporary changes to an eligible captured baseline run through the same frozen Ridge model. Scenarios do not overwrite real inputs or normal prediction history. Public label: **model sensitivity / scenario analysis**. Never promise an individual grade gain or an optimal habit.

**Optional wellbeing:** give this a small supporting section, not the hero. RHR trend compares recent readings with a personal baseline using experimental development thresholds; it does not diagnose illness or create emergency alerts from RHR alone. Body & Wellbeing calculates BMI locally. Complete age/reference information enables CDC BMI-for-age interpretation for ages 2–19; ages 20+ use adult categories. Missing reference information leaves interpretation unavailable. This is a U.S. reference, not a UAE-specific or clinical validation claim.

BMI access in chat is optional, read-only and off by default. Relevant requests use fresh authorized summaries; revocation affects future reads, not cards already saved or exports already shared. None of these wellbeing features changes Ridge output.

## 5. Engineering verification: exact current snapshot

**Latest recorded complete gate: 6 October 2026, 02:21–03:00 Asia/Dubai.** Xcode 26.6; iPhone 17 Pro simulator on iOS 26.5. These results were verified from the latest project ledgers for this handoff, not rerun during handoff preparation.

| Evidence | Exact recorded result |
| --- | --- |
| Complete suite executions | **534/534 PASS** |
| Distinct test cases | **531/531 PASS** |
| Execution split | **492 unit + 42 UI executions** |
| Why the counts differ | There are 39 distinct UI methods; the launch method runs four configurations. |
| Failures / skips | **0 / 0** in the final complete gate |
| V2 golden parity | **176/176 PASS** |
| Preserved V1 golden parity | **21/21 PASS** |
| Parity tolerance | **1e-6**; maximum absolute error approximately **2.84217e-14** |
| Explicit Xcode Build | **PASS**, 6 October |
| Explicit Xcode Analyze | **PASS**, 6 October |
| Compiler / analyzer warnings | **0 / 0** |
| Build / compiler errors | **0** |
| Separate runtime findings | **Two Body-layout runtime entries and one grouped debugger-termination warning** remain recorded. |
| Selected iPad checks | Four cases have passing executions on identical source: initial **2/4**, then unchanged failed-case rerun **2/2**. Do not call the first batch a pass or this a complete iPad suite. |
| Physical acceptance | **PENDING** for the latest source |
| Feature/UI freeze | **NOT DECLARED** |
| Real-student predictive validation | **NOT ESTABLISHED** |

Parity profiles are checked inside unit-test methods; **do not add 176 and 21 to the 534 execution total**. Do not call 534 “unique tests,” “students,” “clinical cases” or “prediction accuracy.” Earlier failing attempts and harness corrections exist; the final pass is not evidence that every earlier run succeeded.

Ready-to-use evidence caption:

> On 6 October 2026, the complete simulator suite passed 534 executions across 531 distinct cases. V2 matched all 176 golden profiles, with 21 legacy V1 profiles preserved. Build and Analyze passed. Final physical acceptance remains pending. These checks verify exercised software behavior, not real-student prediction accuracy.

Keep the remaining runtime findings in visible expandable engineering detail. Do not use a blanket “zero warnings,” “bug-free,” “fully validated” or “release-ready” badge.

## 6. Research facts and the public story

### Evidence strength is unequal

| Input | Current review rating | Meaning for the website |
| --- | --- | --- |
| Previous score | **STRONG SUPPORT** | Strongest basis for later attainment level; not a limit on potential. |
| Study minutes | **MIXED / INCONSISTENT** | Time does not measure learning quality, strategy or completion. |
| Sleep duration | **MIXED / INCONSISTENT** | Duration differs from quality, regularity and timing. |
| Recreational screen time | **MIXED / INCONSISTENT** | Activity, purpose, timing and displacement matter. |
| Apple Exercise Time | **WEAK DIRECT SUPPORT** | Exercise-program and fitness findings do not directly validate this field. |
| Steps | **WEAK DIRECT SUPPORT** | Exploratory movement-volume proxy; direct academic evidence includes nulls. |
| Resting heart rate | **INSUFFICIENT DIRECT EVIDENCE** for a dependable academic predictor | Direct studies exist, but do not establish consistent added predictive value. |

These are critical-review judgments, not medical ratings or formal evidence-certification badges. None validates V2's fitted coefficient or exact input window. Prefer a readable table or labeled evidence ladder; do not invent numerical strength percentages.

### NetHealth: the completed comparison

**207 students; 963 repeated student-semester observations**, from a U.S. undergraduate cohort. The outcome was a term's unweighted mean course grade points on a **0–4 scale**, not a UAE school assessment percentage.

| Metric | Prior-performance baseline | Change after adding available wearables |
| --- | ---: | ---: |
| MAE, 0–4 grade points | Approximately **0.17127** | **+0.00003** |
| RMSE, 0–4 grade points | Approximately **0.23888** | **+0.00053** |
| R² | Approximately **0.52495** | **−0.00181** |

These are reported **means across 50 validation folds**. Positive error changes mean worse prediction. Separately pooled estimates also showed no convincing improvement, but are a different estimator; do not mix their intervals with these fold means.

**Conclusion:** no convincing incremental wearable predictive value beyond prior performance in that cohort and design. The available wearable block used sleep, steps, activity and **average daily HR**, not TwinTrack resting HR. Study and recreational screen inputs were absent. Population, target and windows differ. **This analysis does not validate deployed V2.** The 963 rows are not 963 independent students, and the result does not prove healthy behaviors have no value.

No new NetHealth analysis was run for the website or research handoff. Do not publish the local frozen report or raw data automatically; publish an approved aggregate summary with methods and limitations.

### Other study statuses

| Study | Accurate status |
| --- | --- |
| NetHealth | Only completed TwinTrack participant-level real-data comparison. |
| HSLS:09 | Access/variable audit and analysis protocol prepared; participant-level comparison **not completed**. |
| MCS | Planning/historical research only; original plan file unavailable locally; **no completed TwinTrack participant analysis**. |
| COMPASS | Researched candidate; **no completed TwinTrack participant analysis**. Published external COMPASS research is not TwinTrack's own analysis. |

Never display four dataset logos under “validated on.” A strategy report, codebook, variable map or prepared protocol is not an executed study.

### Public research references

Use compact citations with expandable context, not a bibliography wall:

- Prior attainment: [Rimfeld et al., 2018](https://doi.org/10.1038/s41539-018-0030-0).
- Homework quantity versus evidence for a time dose: [Guo et al., 2024](https://doi.org/10.1002/cl2.1431).
- Adolescent sleep-duration evidence: [Musshafen et al., 2021](https://doi.org/10.1016/j.sleep.2021.04.015).
- Screen activities and academic outcomes: [Adelantado-Renau et al., 2019](https://doi.org/10.1001/jamapediatrics.2019.3176).
- Activity interventions: [Vasilopoulos et al., 2023](https://doi.org/10.1007/s10648-023-09760-2).
- Direct prospective steps study: [Li et al., 2026](https://doi.org/10.1001/jamanetworkopen.2026.36973).
- Direct secondary-school RHR study: [Canli et al., 2024](https://doi.org/10.3390/children11040396).
- Digital-twin definition and validation: [National Academies, 2024](https://doi.org/10.17226/26894).

These external sources explain the review; none is a validation study of the TwinTrack app. NetHealth's project-specific result should link to a sanitized public summary only after one is approved and available.

## 7. PUBLIC CLAIMS

Evidence keys for this portable table: **P** = product/architecture facts in sections 2–4; **T** = dated test ledger in section 5; **R** = research and study status in section 6. Section 19 names the underlying project documents for provenance; their contents are summarized here.

| Possible claim | Verdict | Recommended public wording | Qualification / source | Avoid |
| --- | --- | --- | --- | --- |
| Native SwiftUI iPhone app | **SAFE** | “A native iPhone prototype built with SwiftUI.” | P; selected iPad coverage is separate. | “Available for everyone on iOS.” |
| Integrated HealthKit | **SAFE** | “Reads supported data from Apple Health through HealthKit.” | P; permission and availability required. | “Reads every health metric” or direct vendor integrations. |
| Uses Apple Foundation Models | **SAFE WITH QUALIFICATION** | “On-device conversation and explanation with Apple Foundation Models, when available.” | P; runtime eligibility/readiness applies. | Universal device availability or flawless answers. |
| Uses on-device Ridge | **SAFE** | “Frozen Ridge V2 calculates estimates locally.” | P; deterministic numerical inference. | “The chatbot invents the score.” |
| Seven behavioral/academic inputs | **SAFE WITH QUALIFICATION** | “Seven wearable and manually entered academic/behavioral inputs.” | P; context metadata and wellbeing remain separate. | “Seven proven causes of grades.” |
| Predicts student grades | **DO NOT USE** unqualified | “Generates experimental assessment-score estimates.” | P/R; restricted target and unverified accuracy. | Broad grade forecasting as established capability. |
| Predicts upcoming assessment scores | **SAFE WITH QUALIFICATION** | “Produces an experimental estimate for an eligible upcoming same-subject assessment.” | P/R; 1–7-day product window, not validated horizon. | “Know your next result.” |
| Uses machine learning | **SAFE** | “Uses standardized Ridge Regression.” | P; synthetic-trained V2. | Real-student training claims. |
| Uses AI | **SAFE** | “Ridge handles numbers; Foundation Models supports conversation.” | P; keep the two paths distinct. | AI as an unexplained accuracy guarantee. |
| Digital twin | **SAFE WITH QUALIFICATION** | “Digital-twin-inspired student reflection prototype.” | R; scoped representation, not a complete replica. | Validated physiological or causal learner twin. |
| Personalized | **SAFE WITH QUALIFICATION** | “Applies a shared model to the user's recorded inputs.” | P/R; no learned individual academic coefficients. | “Learns exactly how your body affects grades.” |
| Evidence-informed | **SAFE WITH QUALIFICATION** | “Evidence-informed and explicitly experimental.” | R; includes contrary findings and limitations. | Every coefficient scientifically established. |
| Scientifically validated | **DO NOT USE** | “Prospective predictive validation remains future work.” | R. | “Scientifically proven accurate.” |
| Tested with 534 executions | **SAFE WITH QUALIFICATION** | “534/534 simulator executions passed on 6 October 2026.” | T; 531 distinct cases; date and scope required. | 534 unique tests or 100% prediction accuracy. |
| Validated on real students | **DO NOT USE** for V2 | “A separate NetHealth real-data comparison was completed.” | R; different model/data/target question. | Treating the cohort as V2 app users. |
| Conducted real-data research | **SAFE WITH QUALIFICATION** | “The project includes a completed NetHealth comparison.” | R; no new participant recruitment implied. | Four completed dataset validations. |
| Wearables improve prediction | **DO NOT USE** as a project result | “Added wearable value remains unestablished.” | R; completed comparison found no convincing increment. | Hiding or reversing the null finding. |
| Helps students improve grades | **DO NOT USE** as a measured outcome | “Designed to support student reflection.” | R; usefulness/impact need user studies. | Proven grade or wellbeing improvement. |
| Privacy-first | **SAFE WITH QUALIFICATION** only as specific design facts | “Local processing, permission-controlled access and explicit data controls.” | P; no compliance/security certification. | “Completely private,” “risk-free.” |
| Runs locally | **SAFE WITH QUALIFICATION** | “Academic calculations and app-owned stores are local; chat export is user-initiated.” | P; distinguish app behavior from OS/services and sharing. | “Nothing can ever leave your phone.” |
| Clinically validated wellbeing | **DO NOT USE** | “Optional, non-diagnostic wellbeing information.” | P/R. | Medical-device, diagnosis or emergency-detection claims. |
| Apple approved / App Store ready | **DO NOT USE** without new evidence | “Experimental native prototype.” | Release/platform review unresolved. | Store badges, Apple endorsement or download availability. |

## 8. Recommended site architecture and depth

**Recommendation:** a strong overview case-study page plus **Research** and **Engineering & Evidence** pages, if the existing framework supports this cleanly. Keep brief project context near the overview footer; a separate empty About page adds little. If the current single page is excellent, preserve it and use anchored sections plus accessible disclosures rather than rebuilding for page count.

| Layer / destination | Purpose and audience | Content | Priority |
| --- | --- | --- | --- |
| 20 seconds: overview hero | QR visitors, CV reviewers, admissions | Product identity, real app visual, one-sentence purpose, experimental label, demo CTA | P0 |
| 2 minutes: overview case study | Judges and portfolio readers | Three-tab experience, data flow, Ridge/AI separation, What-If, key evidence and what changed the framing | P0 |
| 10+ minutes: Research | Research-minded readers | Unequal feature evidence, NetHealth method/null, study statuses, limitations and prospective plan | P0 |
| 10+ minutes: Engineering & Evidence | Technical interviewers | Architecture, data lifecycle, deterministic parity, dated tests, acceptance boundaries, selected sanitized downloads | P0 |
| Development timeline | Readers seeking project history | Confirmed product and research milestones | P1 |

Do not repeat the same dense limitations block on every section. Keep a short qualification close to estimates and evidence, with a deeper linked explanation. Make the website understandable without downloads, then offer detail.

Appropriate CTAs: **Watch Demo, See the App, Explore the Engineering, Read the Research, View Evidence**. “Download Evidence Summary” appears only when a real sanitized file exists. No App Store download, Sign Up, Try Prediction or Get Started CTA without an actual approved destination/capability. Preserve the existing URL and QR destination unless the owner explicitly authorizes a change.

## 9. Audit the existing website before editing

Inspect the current implementation and produce one section-by-section audit using **KEEP / IMPROVE / REBUILD / MOVE / MERGE / REMOVE / ADD**. For each decision, record the observed issue, proposed improvement and factual/visual acceptance condition. Preserve excellent work.

Audit:

- Hero, hierarchy, section order, navigation, typography, spacing, grid and visual rhythm.
- Screenshot fidelity/scale, diagram clarity, demo placement, motion and empty/placeholder content.
- Phone, iPad and desktop behavior; keyboard access, focus, contrast and reduced motion.
- Image/font/video weight, unnecessary JavaScript, loading behavior, console errors and broken links.
- Model/version wording, seven features, dated testing numbers, research accuracy, physical status and privacy wording.
- Project identity, obsolete technology references, evidence depth, metadata and social preview.
- Current deployment URL, existing QR target and public-link availability without changing them by assumption.

Do not publish this audit as part of the case study. It is implementation guidance for the website chat.

## 10. Visual direction and quality requirements

Aim for polished Apple-developer/technical-case-study quality. Use deep navy, near-black, white and cyan/electric blue, with restrained violet where it helps distinguish conversational AI. Gradients may support the website composition; do not recolor or redesign the actual app screenshots.

Use the approved blue light/dark TwinTrack marks, preserving proportions and transparency. **Do not convert them to monochrome.** Website backgrounds must provide adequate contrast; logo artwork does not justify low-contrast text. The app's Home-only logo rule concerns the app, not the website masthead.

Favor strong typography, generous spacing, large real app visuals, clean diagrams and restrained motion. Vary compositions: product-led hero, full-width app sequence, architecture, research comparison, timeline and expandable evidence. Avoid a site made entirely of repeated three-card grids, giant glows, cyberpunk effects, generic AI art, stock students, fake dashboards, decorative icon clutter or tiny screenshots.

Test approximately **390, 430, 768, 1024 and 1440 px**, plus intermediate widths. Require no horizontal overflow, readable tables/diagrams, comfortable touch targets, responsive video, useful mobile navigation and no hover-only information. A wide architecture diagram should reflow into steps on phones, with equivalent text.

Accessibility essentials: semantic heading order and landmarks; meaningful alt text; real links/buttons; keyboard navigation and visible focus; adequate contrast; labeled non-color-only statuses; reduced-motion support; accessible disclosures; captions/transcript for the demo. Audit the experience rather than claiming formal compliance without testing.

Performance essentials: responsive optimized images, lazy loading below the fold, an appropriately prioritized hero image, limited font weights, minimal unnecessary JavaScript and poster-first lazy video. Avoid autoplay audio and heavy decorative dependencies. Report measured mobile performance and actual test conditions rather than promising a perfect score.

## 11. Ready-to-use public copy

These are modular copy blocks, not an instruction to create twenty separate sections. Merge them according to the existing site's strengths. Do not add contribution or development-authorship content.

### A. Hero

**TwinTrack AI**

**See the context behind the estimate.**

A native iPhone prototype bringing academic inputs, Apple Health context and on-device conversation into one place for reflection and exploratory What-If comparisons.

**Evidence-informed. Explicitly experimental.**

Ridge V2 was developed with synthetic data; its real-student assessment accuracy remains unverified.

CTAs: **Watch Demo** · **Explore the Project**

Keep the Watch Demo button hidden until the actual video is available.

### B. Short project description

TwinTrack is a digital-twin-inspired student reflection prototype. A frozen Ridge model generates experimental assessment estimates; Apple Foundation Models supports conversation and explanation. The two roles stay deliberately separate.

### C. Problem

Study records, assessment results and wearable summaries often sit in different places. TwinTrack explores a focused question: can bringing that context together make a student's recorded profile and model scenarios easier to understand?

### D. How it works

Review four accessible Apple Health values, enter three academic and behavioral inputs, and confirm the assessment context. When the data meets the app's eligibility rules, an explicit run calculates an estimate locally and saves its source context.

### E. Seven inputs

Sleep, steps, exercise minutes and resting heart rate come from accessible Apple Health data. Study time, recreational screen time and the previous comparable score are entered manually. Their scientific support is unequal, and missing inputs remain unavailable.

### F. Ridge / model

**A reproducible numerical core.**

TwinTrack Ridge V2 2.0-final.1 applies the same frozen calculation to the same valid inputs. It was developed with synthetic data for engineering and scenario testing. Its real-student predictive accuracy has not yet been established.

### G. What-If

**Explore a scenario, not a promise.**

Change a temporary input profile and compare estimates from the same Ridge model. The result shows model sensitivity. It does not establish what changing a habit would cause, and it leaves the recorded baseline unchanged.

### H. TwinTrack AI

**Conversation around grounded results.**

Apple Foundation Models supports questions and explanations on supported, ready devices. TwinTrack's own tools provide the numerical cards; conversational text does not become an authoritative score or health measurement.

### I. App experience

**Home** brings estimates, source context and the next useful action together. **TwinTrack AI** supports conversation and What-If exploration. **Profile** holds manual inputs, local data controls, appearance, Trends & History and optional wellbeing information.

### J. Research

**Evidence that challenges the idea matters too.**

The research review found the strongest academic support for previous performance. Study duration, sleep duration and recreational screens have mixed evidence; the exact wearable activity and RHR inputs have weaker direct support. The project remains an experimental prototype rather than a validated grade-prediction service.

### K. NetHealth

**A useful negative result.**

The completed NetHealth comparison covered 207 students and 963 repeated student-semester observations. Adding the available wearable measures did not convincingly improve prediction beyond prior performance. Different inputs, students and outcomes mean this study does not validate TwinTrack V2.

### L. Seven-input evidence summary

**Seven inputs. Unequal evidence.**

Previous score has the strongest foundation. Study, sleep and recreational screen duration are context-dependent. Apple Exercise Time, steps and resting heart rate remain exploratory academic signals. Evidence for healthy behavior is not the same as evidence of added prediction accuracy.

Use the labeled evidence table from section 6 beneath this copy.

### M. Engineering / testing

**Tested behavior, with a clear boundary.**

The 6 October 2026 simulator gate passed 534 executions across 531 distinct cases. V2 matched 176 golden profiles, and 21 V1 profiles remain preserved. Build and Analyze passed. Final physical acceptance is pending; software verification does not establish real-student prediction accuracy.

### N. Development journey

TwinTrack evolved from an earlier local prototype into a native SwiftUI app with read-only HealthKit integration, a deterministic numerical core and on-device conversation. Later work strengthened data provenance, saved-result handling and the distinction between research evidence and product claims.

### O. Privacy / responsible AI

**Local processing. Explicit controls.**

TwinTrack reads permitted Health data, stores app records locally and provides separate controls for saved estimates and chats. Optional BMI chat access requires permission. Export is user-initiated. These design choices do not amount to a legal-compliance or zero-risk guarantee.

### P. Limitations

V2 is synthetic-trained and lacks prospective validation in its intended student population. Inputs are imperfect measurements with unequal evidence; device availability and missing data can affect who receives an estimate. What-If is non-causal, and no calibrated real-student prediction interval is available yet.

### Q. Future validation

The next meaningful test is frozen V2 against a previous-score baseline on real upcoming same-subject assessments. A prospective study should examine error, calibration, coverage and uncertainty, while a separate user study checks understanding, appropriate trust and usefulness.

### R. Project context

TwinTrack AI is a Grade 12 graduation project exploring student reflection, on-device modeling and responsible use of academic and wellbeing information.


### S. Demo

**See the current prototype in action.**

A short walkthrough of Home, a real Ridge calculation, a temporary What-If scenario and a saved-estimate explanation. All visible profile and health values are fictional demonstration data.

Until the video exists, use “Demo recording in preparation” without a fake player or dead button.

### T. Portfolio short summary

TwinTrack AI is a native SwiftUI student reflection prototype combining read-only HealthKit context, a frozen seven-input Ridge model, deterministic What-If analysis and Apple Foundation Models conversation. Its evidence separates verified software behavior from still-unverified real-student predictive accuracy.

### What changed the project's thinking?

Wearable signals seemed worth investigating alongside academic history. In the completed NetHealth comparison, they did not add convincing predictive value beyond prior performance. The wider review also found unequal support across the seven inputs. The project's framing became more precise: an evidence-informed reflection prototype with a testable research question, not a scientifically validated grade predictor.

## 12. Confirmed development timeline

Use milestone titles and brief descriptions, not invented weeks, votes or personal achievements. Dates below are documented project/commit dates, not guarantees of the first day work began.

| Date | Public milestone | Concise description |
| --- | --- | --- |
| Earlier prototype; exact date unconfirmed | Explore the numerical workflow | Repository history documents a Windows/Python Ridge prototype and local Qwen3 4B/Ollama conversation. These are historical, not the current mobile stack. |
| 7 September 2026 | Establish the native foundation | Three SwiftUI tabs, frozen V1 Ridge with 21-profile parity, shared state and persistent manual inputs. |
| 8–9 September 2026 | Connect data and scenarios | Read-only HealthKit, Home, deterministic What-If, saved estimates/trends and refresh/timing corrections. |
| 9–15 September 2026 | Add on-device conversation | Foundation Models implementation and focused reliability/safety work. A September freeze label describes that historical checkpoint, not current acceptance. |
| 21 September 2026 | Integrate the explicit V2 contract | Ridge 2.0-final.1, dated same-subject assessment eligibility and 176-profile V2 parity; V1 preserved. |
| 21–22 September 2026 | Separate optional wellbeing | Experimental personal RHR trend, Manual Inputs refinement and optional age-aware BMI. Wellbeing does not alter academic prediction. |
| 24–30 September; committed 1 October | Strengthen context and saved records | Grounded calculation/scenario routing, consent-controlled BMI reads, Trends & History and exact saved-estimate explanations. |
| 6 October 2026 | Consolidate verification and research | Complete 534-execution automated pass and deeper evidence review; physical acceptance and prospective predictive validation remain distinct open steps. |

Historical ideas supplied by the owner include Smart Interview Trainer, AI Speech Buddy and TwinTrack AI; TwinTrack was selected. No verified selection scores, votes or documented rationale were found in the inspected sources. Omit an idea-selection story unless the underlying record is supplied. Fitbit Charge 6, Flutter, Firebase and cloud/API concepts are not corroborated current architecture; do not put them in the public timeline without a dated historical source.

## 13. Public evidence hub and downloads

Publish selected evidence, not the private repository or raw development archive.

| Material | Best placement | Publication condition |
| --- | --- | --- |
| Architecture and three-tab app experience | Directly on-page | Diagram agrees with this handoff; screenshots are genuine and approved. |
| Dated test/parity summary | On-page with expandable detail | Distinguish executions/cases, runtime notices and pending physical acceptance. |
| Evidence-strength matrix and NetHealth conclusion | On-page Research | Include limitations and useful source links. |
| Model/version/feature contract | Expandable Engineering detail | Explain synthetic training and non-causal scenarios. |
| Future validation plan | Research summary; optional download | Label proposed, not executed or preregistered externally. |
| Research/evidence PDF or Markdown | Optional sanitized download | Standalone title/date, units, scope, references, readable layout and reviewed public content. |
| Demo and transcript | Prominent overview section | Fictional data; real current UI; actual Ridge outputs; honest AI availability. |
| Raw logs, result bundles, screenshots from private testing, internal handoff | **Remain private** | Do not upload merely because available. |
| Participant data, Health/BMI records, chats/photos, identifiers, credentials, signing files | **Do not publish** | Never include in the website bundle or public downloads. |

A public export must remove local machine paths, account/device details, private repository links, private evidence references, internal workflow notes and unapproved names/images. Preserve substantive limitations, study status and unfavorable findings; sanitization must not turn into selective evidence reporting. Inspect image/PDF metadata and the generated downloadable file itself.

The website laptop should not need an iOS checkout. This handoff contains the essential model, architecture, verification and research facts. Additional raw project documents are neither required nor automatically public-safe.

## 14. Portable asset manifest

Only branding assets were visually inspected for this handoff. No new app screenshot, device capture or video was made. The inspected repository/work folder did not contain an approved current public screenshot set, a final demo video or a current presentation deck. This does not establish what exists on another laptop or in a cloud design tool.

Paths below are relative to the TwinTrack repository; copy only the named safe assets, retaining recognizable filenames.

| Asset | Need | Known file / current status | Direction |
| --- | --- | --- | --- |
| Dark TwinTrack mark | **REQUIRED** | `design/assets/TwinTrack_Logo_Assets/Dark/twintrack-mark.png`, 716 × 360, transparent | Approved original blue/dark artwork; preserve proportions. |
| Light TwinTrack mark | **REQUIRED** | `design/assets/TwinTrack_Logo_Assets/Light/twintrack-mark-light-3x.png`, 612 × 309, transparent | Approved light variant; do not render monochrome. |
| Square app icon | **REQUIRED** for app identity/favicon source | `ios/twintrack/twintrack/Assets.xcassets/AppIcon.appiconset/TwinTrackAppIcon.png`, 1024 × 1024 | Dark background, approved mark; do not stretch the wide header into a square. |
| Home screenshot | **REQUIRED** | New approved capture needed; proposed transfer name `home-current-demo.png` | Compact current card, source labels and fictional data. |
| TwinTrack AI screenshot | **REQUIRED** | Proposed `chat-current-demo.png` | Current compact chat; genuine accepted state, no private conversation. |
| Profile screenshot | **REQUIRED** | Proposed `profile-current-demo.png` | Blue Ridge above purple Foundation Models; no private profile. |
| What-If screenshot | **REQUIRED** | Proposed `what-if-current-demo.png` | Actual frozen-engine comparison, fictional eligible inputs. |
| Trends/history screenshot | **OPTIONAL**, valuable | Proposed `history-current-demo.png` | Genuine app UI with disclosed synthetic history; no invented chart points. |
| Light/Dark and iPad companion views | **OPTIONAL** | Not supplied here | Capture current build; do not imply complete physical approval. |
| Architecture/research visual | **REQUIRED** | Website-native rendering from this handoff | Labeled data flow/evidence, not a fake app screen. |
| 60–90 second demo + poster/transcript | **REQUIRED** for completed showcase; optional for a clearly labeled initial case study | Not supplied; proposed `twintrack-demo.mp4`, `demo-poster.jpg`, `demo-transcript.txt` | Review fictional-data/privacy disclosure before publication. |
| ATS / ACTVET logos | **OPTIONAL, approval required** | No verified local files found in inspected folders | Obtain official artwork and permission/context; no endorsement inference. |
| Social preview | **REQUIRED** before public sharing | To compose in website workspace from approved assets | TwinTrack mark + real app view + restrained title; no accuracy badge. |
| Favicon | **REQUIRED** | Derive/export from approved square app icon in website workspace | Check small-size readability; no new branding treatment. |
| September UI-design screenshots/HTML | **DO NOT USE as current product evidence** | Historical references named in old UI handoff | Useful for history only when explicitly dated; layouts and model behavior changed. |
| `ridge_21_of_21_parity_pass.png`, `ridge_parity_xcode_context.png` | **DO NOT USE as current V2 evidence** | Historical V1 files in `evidence/ridge_parity/` | Prefer a sanitized dated textual current summary; wider developer screenshots may expose identifiers. |
| `manual_inputs_verified.png`, `manual_inputs_persistence_verified.png` | **DO NOT USE as current UI** | Historical files in `evidence/manual_inputs/` | Current V2 form/context differ. |
| `ml/results/actual_vs_predicted.png`, `feature_coefficients.png` | **DO NOT USE as current accuracy proof** | Historical modeling plots | Never present synthetic/V1 results as real-student V2 validation. |
| Private physical Health/BMI screenshots or chat archives | **DO NOT USE** | Not inspected for this task | Private debugging approval is not approval for publication. |

Proposed filenames are a transfer checklist, **not claims that the assets already exist**. Keep original screenshot proportions; cropping browser/window chrome is fine only if it removes no important app state or qualification. Never fabricate a production score, alter a measurement or paint over an inconvenient unavailable state.

## 15. Demo brief

Place a **60–90 second** video near the top of the overview with a real poster, captions and transcript. Disclosure: **“Fictional demo data. Estimates calculated by the actual frozen model.”**

| Time | What to show | Suggested narration |
| --- | --- | --- |
| 0–10 s | Current Home | “TwinTrack brings a student's recorded inputs together. This demonstration uses fictional data.” |
| 10–25 s | Inputs/context → explicit Run Prediction → brief Details | “Four values normally come from Apple Health and three are manual. Ridge calculates this experimental estimate locally.” Read the actual displayed result. |
| 25–45 s | Manual What-If, study +30 minutes | “This changes a temporary profile. The comparison shows model sensitivity, not a promised grade gain.” |
| 45–75 s | Open the new saved V2 estimate → Explain this saved estimate | “The explanation belongs to this exact saved record. The app owns its numbers; Foundation Models supplies the conversation.” |
| 75–90 s | Profile/Data & Privacy | “Saved estimates and chats have separate controls. Real-student predictive usefulness still needs prospective evaluation.” |

Use the already implemented isolated synthetic demo setup with the app operator. The website chat must not invent launch arguments or ask for private readings. Do not use a partial test preset that might fall back to real HealthKit. No synthetic data belongs in HealthKit or normal history.

A real conversational reply must be labeled as such only if it actually came from Foundation Models. If unavailable or still generating, disclose that and continue with the deterministic card; do not substitute an injected reply. Editing may remove waiting time if clearly indicated, but must not misrepresent response speed or success. Do not force every acceptance check into the video or present a rehearsal as physical sign-off.

## 16. SEO and public-link quality

**Title:** TwinTrack AI — Student Reflection Prototype

**Meta description:** Explore TwinTrack AI: a native iPhone prototype with on-device Ridge estimates, What-If scenarios and an honest account of its research and testing.

**Open Graph title:** TwinTrack AI — The App, Engineering and Evidence

**Open Graph description:** A digital-twin-inspired student reflection prototype. Explore the app, its numerical architecture, research findings and validation boundaries.

**Favicon:** approved app-icon artwork at suitable small sizes.

**Social preview:** deep navy background, approved TwinTrack mark, one large current synthetic-data app view and “A student reflection prototype.” Keep important content inside safe crop margins and check link previews on mobile.

Use the actual approved URL for canonical/social fields only after confirmation. No invented domain, private GitHub URL, store badge, review stars or structured-data availability claims. Existing school/QR materials must continue to reach the intended page; verify rather than regenerate the QR automatically.

## 17. VOLATILE WEBSITE FIELDS

Keep these values in one website content/config source so hero, evidence, metadata and downloads cannot drift apart.

| Field | Current status | Public fallback | Update trigger |
| --- | --- | --- | --- |
| Physical acceptance | Pending for latest source | “Final physical acceptance pending.” | Dated acceptance record for that exact source. |
| Feature/UI freeze | Not declared | “Experimental prototype.” | Explicit recorded approval; an old freeze commit is insufficient. |
| Complete test result | 534 executions / 531 cases, 6 October | Dated counts and simulator scope | New complete result plus matching source identity. |
| Warnings | 0 compiler/analyzer; 2 Body entries + 1 debugger warning | Separate diagnostic categories | Fresh documented diagnostics; do not silently erase. |
| Parity/model | V2 2.0-final.1, 176 profiles; V1 21 | Current frozen version | Approved version change and new parity evidence. |
| Demo | Final approved video absent | “Demo recording in preparation” or omit section temporarily | Reviewed final video, poster and transcript supplied. |
| Screenshots | No current approved public set supplied | Use approved branding; do not invent UI | Final synthetic captures approved for publication. |
| Institution marks | Artwork/permission not verified | Omit logos and endorsement language | Approved official assets and display context. |
| Public URL / QR | Not supplied or inspected here | No hard-coded replacement | Website owner confirms existing deployment and QR target. |
| Public evidence/download links | Not yet provided | In-page summaries; omit dead download buttons | Sanitized exports hosted at approved public destinations. |
| App Store / platform status | No approval or readiness established | Native experimental prototype | Formal distribution review; never infer from a successful build. |
| Real-student validation | Not established | Explicitly experimental | New completed, methodologically appropriate study. |

Historical test gates, synthetic accuracy metrics, local master handoffs and old screenshots must not automatically update these fields.

## 18. Publication prerequisites and final quality checklist

**Internal platform note:** the research review identified a HealthKit-purpose/distribution question. Review the current product purpose and [Apple's HealthKit privacy requirements](https://developer.apple.com/documentation/healthkit/protecting-user-privacy) before claiming public app-distribution readiness. This is not a finding of a policy violation. Do not publish an accusation, claim Apple approval, or label the app a medical device. A truthful prototype case study can describe the current pending status.

Unresolved items do not block drafting/design. They block the corresponding claim or asset: an honest prototype showcase may be published with pending acceptance clearly stated, but must not become a “final verified release” announcement without sign-off.

### P0 — must be excellent

- Current facts, version, seven-feature contract, explicit-run behavior and non-causal wording are consistent everywhere.
- Hero makes sense in 20 seconds; real app UI is prominent; architecture and evidence are understandable in two minutes.
- Phone layout is strong; screenshots are genuine, current and publicly approved.
- Demo works and is clearly synthetic, or its absence is stated without fake controls.
- Research preserves the NetHealth null, unequal evidence and incomplete dataset statuses.
- Tests, physical acceptance and predictive validation remain separate.
- No private assets, broken core links, fabricated UI or contribution/authorship section.
- Essential accessibility, privacy and performance are release gates, not decorative extras.

### P1 — should be excellent

- Development timeline is dated and accurate; deeper engineering and research are easy to navigate.
- Downloads are sanitized, self-contained and worth reading.
- Typography, spacing, varied composition and restrained motion feel deliberate.
- SEO/social metadata, captions, keyboard navigation, focus and reduced-motion behavior are verified.
- Tablet/desktop layouts are as intentional as phone layouts.

### P2 — optional

Advanced animation and interactive visualizations only if they improve understanding, remain accessible and do not delay P0. Do not add a browser score calculator or fake live dashboard for visual effect.

### Final acceptance checks for the website chat

1. Compare every numerical/public claim with this handoff; date evidence and retain qualifications.
2. Check approximately 390/430/768/1024/1440 px, intermediate widths, zoom and keyboard navigation; no overflow or hidden information.
3. Confirm heading hierarchy, alt text, focus, contrast, interaction semantics, captions and reduced motion.
4. Test every navigation, CTA, download, external citation and video state; no missing assets, placeholders or console errors.
5. Measure mobile loading/performance under stated conditions; optimize images/fonts/video before decorative work.
6. Inspect public files and metadata for private content; no private repository or local-machine links.
7. Verify canonical/social URL and existing QR behavior; no deployment/domain changes without applicable approval.
8. Record desktop/tablet/phone findings, before/after changes and remaining blockers. Do not call untested behavior PASS.

## 19. Provenance, conflicts and unresolved owner confirmations

This handoff was checked against current local Git state: branch `ios-development`, HEAD `2ea2aac`, plus pending source/document changes. HEAD alone does not identify the entire tested working tree. No fetch, app build, new test run, commit, push or deployment was performed for this task. The pre-existing changes were preserved.

Source precedence and what was extracted:

- `docs/FINAL_APP_PASS.md`, `docs/EVIDENCE_LOG.md`: latest October 6 gate, parity, Build/Analyze and separate runtime findings.
- `docs/FINAL_PHYSICAL_ACCEPTANCE.md`, `docs/UI_FREEZE.md`: current physical checklist and not-frozen status; current tabs/features and historical boundaries.
- `docs/ASSISTANT_RELIABILITY_AUDIT.md`: numerical/conversation separation, canonical context, safety limits, consent-controlled fresh BMI reads and saved-chat behavior.
- `docs/FINAL_RESEARCH_SYNTHESIS.md`: latest October 6 scientific position, unchanged NetHealth findings, pending studies, privacy/platform caveat and verdict.
- `docs/TWINTRACK_INPUT_EVIDENCE_MATRIX.md`: exact unequal feature ratings and primary sources.
- `docs/TWINTRACK_FUTURE_VALIDATION_PROTOCOL.md`: proposed frozen prospective comparison, not an executed study.
- `docs/PRESENTATION_RESEARCH_CLAIMS.md`: public wording boundaries; contribution-oriented material is deliberately excluded from this handoff's public copy.
- Current local master handoff and private `DEMO_DEFENSE.md`: operational status and synthetic demonstration guidance were summarized without copying private paths or personal-role material.
- `docs/V2_FINAL_BLOCKER_RESOLUTION.md`, model source and current Profile/runtime/storage source: output bounds, target/context, model identity, visible Ridge/AI cards and local implementation.
- `docs/TwinTrack_UI_Handoff.md` and branding asset READMEs: approved emblem provenance and historical visual system. Its September 5 layouts, large score styling, V1-only parity and earlier prediction-save behavior are superseded.
- Git milestone history and `docs/CHANGE_HISTORY.md`: dated development milestones.
- Root `README.md`: historical Windows/Python/Qwen/Ollama prototype; its “current” wording is stale for today's iOS app.

No current presentation deck or publication-ready app media was found in the inspected repository/work folder. No claim is made about files on another laptop or in ChatGPT/Canva. The website chat must compare any such materials against this current factual snapshot.

**Owner confirmations still needed:** approved current screenshots/video; official institutional artwork/permission if desired; existing public URL/QR destination; approved public evidence files/links; final physical acceptance when completed. No contribution breakdown is needed for this website.

**Transfer now:** this complete handoff plus the two approved logo PNGs and square app icon named in section 14. **Transfer later:** approved synthetic app screenshots and final demo/poster/transcript. Do not transfer the private repository, local research folder, raw results, private briefing files or personal evidence as website assets.

## 20. Instructions to the website Work chat

1. Read this entire handoff; it contains the necessary facts without requiring the iOS repository.
2. Inspect the **existing** website before editing.
3. Produce a KEEP / IMPROVE / REBUILD / MOVE / MERGE / REMOVE / ADD audit.
4. Compare all existing content with this factual snapshot; flag conflicts rather than guessing.
5. Preserve anything already excellent.
6. Substantially improve weak visual design and information architecture without inventing app features.
7. Use the ready-to-use copy, adapting length and placement while retaining evidence boundaries.
8. Replace stale technologies, UI references, unsafe research claims and misleading test badges.
9. Centralize volatile facts and use honest fallbacks for missing media or approvals.
10. Make the site a strong project showcase; keep contribution and development-authorship material out of public content.
11. Test desktop, tablet and phone, plus accessibility, links, media, metadata and performance.
12. Do not invent TwinTrack facts, results, team roles, assets, URLs or endorsements.
13. Return a final before/after summary, exact verification results, unresolved items and what still requires approval before publication.
