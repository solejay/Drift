# Product Requirements Document: Drift

## Document Information
- **Version**: 1.0
- **Last Updated**: January 17, 2026
- **Author**: Product Team
- **Status**: Draft

---

## 1. Executive Summary

### Elevator Pitch
Drift shows you where your money quietly disappears — no budgets, no guilt, just a daily mirror that builds awareness over time.

### Problem Statement
People make dozens of small, friction-free purchases daily (Uber Eats, Amazon, coffee) that feel insignificant in isolation but compound into significant monthly spending. The brain doesn't naturally aggregate these micro-transactions, leading to the recurring shock of "where did all my money go?"

**Current State**: Users either ignore their spending until they check their bank balance (reactive shock), or they use complex budgeting apps that require active engagement and goal-setting (high friction, low sustained usage). Most people rely on gut feeling for purchase decisions with zero real-time feedback.

**Desired State**: Users receive passive, non-judgmental awareness of their spending patterns through daily and weekly summaries — allowing natural behavior change through visibility rather than willpower.

**Gap**: No existing solution provides simple, passive spending awareness focused on "leaky bucket" categories without requiring budgets, goals, or active app engagement.

### Target Audience

#### Primary Users
- **Segment**: Young professionals and millennials who are financially stable but not actively budgeting
- **Demographics**: Ages 25-40, urban/suburban, employed, income $50K-$150K
- **Size**: Estimated 45M+ in North America who use food delivery, Amazon, and have "where did my money go?" moments

#### Secondary Users
- Couples who want shared visibility into specific spending categories
- Parents wanting to model financial awareness for family
- Anyone beginning their financial awareness journey but intimidated by full budgeting apps

### Unique Selling Proposition
Drift is the anti-budgeting app. No goals to set, no categories to configure, no guilt when you "fail." Just honest, passive awareness of where your money goes — delivered in 10 seconds a day.

**Competitive Advantage**: 
- Radical simplicity (one notification, one weekly screen)
- Focus on "leaky buckets" rather than all spending
- Reflective rather than interruptive — summaries come after the day, not during decisions
- No judgment, no goals, no gamification — just the mirror

**Why Now**: 
- Subscription fatigue with complex finance apps (Mint shutting down, budget app churn)
- Post-pandemic normalization of delivery services has created new "invisible" spending habits
- Growing interest in mindfulness approaches to personal finance

### Success Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Daily Active Users (DAU) | 10,000 in 6 months | Analytics dashboard |
| Notification Open Rate | >40% | Push notification analytics |
| Weekly Summary Engagement | >60% view rate | Screen view tracking |
| 30-Day Retention | >35% | Cohort analysis |
| User-Reported Behavior Change | >50% notice spending changes | In-app survey at 30 days |
| NPS Score | >40 | Quarterly in-app survey |

---

## 2. User Personas

### Persona: Alex — The Unconscious Spender

#### Demographics
- **Role/Title**: Product Manager at a tech company
- **Age Range**: 32
- **Location**: Toronto, Canada (suburban)
- **Tech Savviness**: High
- **Industry**: Technology

#### Goals
1. Understand where discretionary money actually goes each month
2. Reduce spending on delivery apps without feeling deprived
3. Build better financial habits without the overhead of detailed budgeting

#### Pain Points
1. Opens bank app, sees low balance, has no idea how it got there
2. Has tried Mint/YNAB before but stopped using them within weeks
3. Feels vague guilt about spending but no concrete data to act on

#### Behaviors
- **Frequency of Need**: Daily spending, weekly reflection
- **Current Tools**: Bank app (rarely), mental math (unreliable)
- **Decision Criteria**: Must be effortless; will abandon anything requiring daily input

#### Quote
> "I make good money, but I have no idea where it goes. I don't want a finance app — I just want to *know*."

#### Scenario
Alex orders Uber Eats for the third time this week. At 8 PM, a notification appears: "Today: $47 — Uber Eats $32, Amazon $15. This week: $156 on your tracked categories." Alex thinks, "Huh, that's more than I realized." On Sunday, Alex opens the weekly summary, sees the visual breakdown, and decides to cook more next week — not because the app told them to, but because they finally *see* the pattern.

---

### Persona: Maya — The Aspiring Saver

#### Demographics
- **Role/Title**: Marketing Coordinator
- **Age Range**: 27
- **Location**: Vancouver, Canada
- **Tech Savviness**: Medium-High
- **Industry**: Marketing/Advertising

#### Goals
1. Save for a down payment on a condo
2. Identify and reduce "invisible" spending that undermines savings goals
3. Feel in control of finances without obsessing over every dollar

#### Pain Points
1. Makes decent income but savings account grows slower than expected
2. Knows she overspends on "little things" but doesn't know the real numbers
3. Budgeting apps feel like homework and trigger anxiety

#### Behaviors
- **Frequency of Need**: Daily awareness, weekly accountability
- **Current Tools**: Spreadsheet (updated sporadically), bank app
- **Decision Criteria**: Needs to feel supportive not judgmental; visual appeal matters

#### Quote
> "I don't need someone telling me I spent too much on coffee. I just need to see the truth so I can make my own decisions."

#### Scenario
Maya connects her bank account, selects "Food Delivery," "Coffee Shops," and "Amazon" as her leaky buckets. Each evening, she gets a single notification. After two weeks, she realizes she's spending $400/month on food delivery alone. She doesn't set a budget — she just starts ordering less because the number is now real to her.

---

### Persona: Jordan & Sam — The Aware Couple

#### Demographics
- **Role/Title**: Software Engineer (Jordan) & Teacher (Sam)
- **Age Range**: 35 and 33
- **Location**: Austin, Texas
- **Tech Savviness**: High (Jordan), Medium (Sam)
- **Industry**: Tech / Education

#### Goals
1. Have visibility into shared discretionary spending without micromanaging each other
2. Align on reducing dining out spending for a vacation fund
3. Maintain financial harmony without awkward "budget meetings"

#### Pain Points
1. Neither knows what the other spends on personal categories
2. Joint budget conversations feel accusatory
3. Want accountability without surveillance

#### Behaviors
- **Frequency of Need**: Weekly sync on shared visibility
- **Current Tools**: Shared credit card (no tracking), occasional conversations
- **Decision Criteria**: Must support couples without creating conflict

#### Quote
> "We're not trying to police each other. We just want to see the same picture."

#### Scenario
Jordan and Sam both install Drift. They each select "Dining Out" as a shared visibility category. Each Sunday, they both see the combined total. No individual amounts, just the shared number. It becomes a low-stakes conversation starter: "We hit $380 on dining out this week — want to cook Friday?"

---

## 3. Feature Specifications

### Feature Priority Matrix

| Feature | Priority | Effort | Value | Status |
|---------|----------|--------|-------|--------|
| Bank Connection (Plaid) | P0 | L | H | Planned |
| Leaky Bucket Selection | P0 | S | H | Planned |
| Daily Evening Notification | P0 | M | H | Planned |
| Weekly Visual Summary | P0 | M | H | Planned |
| Onboarding Flow | P0 | M | H | Planned |
| Category Customization | P1 | M | M | Planned |
| Trend Analysis (Premium) | P1 | M | M | Planned |
| Shared Category Tracking | P1 | L | M | Planned |
| "What If" Projections (Premium) | P2 | M | M | Backlog |
| Export/Reports (Premium) | P2 | S | L | Backlog |

---

### Feature: Bank Account Connection

#### Overview
Users connect their bank accounts via Plaid to enable automatic transaction categorization. This is the foundation of all spending awareness features — without transaction data, the app cannot function.

#### User Story
**As a** new user,  
**I want to** securely connect my bank account,  
**So that I can** see my spending without manual entry.

#### Acceptance Criteria

**Happy Path:**
- Given the user is on the onboarding screen
- When they tap "Connect Bank Account" and complete Plaid Link
- Then their account is connected and transactions begin syncing within 60 seconds

**Validation:**
- Given the user's bank requires MFA
- When they complete the MFA challenge in Plaid
- Then the connection completes successfully

**Edge Cases:**

| Scenario | Expected Behavior |
|----------|-------------------|
| Bank not supported by Plaid | Show message: "Your bank isn't supported yet. We're adding new banks regularly." with email signup for notification |
| Connection timeout | Allow retry with clear messaging |
| User cancels mid-flow | Return to previous screen, offer to try again later |
| Multiple accounts at same bank | Allow user to select which accounts to track |

#### Priority
**Level**: P0

**Justification**: Core functionality — app is unusable without transaction data.

#### Dependencies
- **External Dependencies**: Plaid API integration
- **Technical Requirements**: Secure token storage, PCI-compliant handling

#### Technical Constraints
- Plaid Link SDK must be integrated for iOS/Android
- Transaction sync should happen in background
- Must handle Plaid API rate limits gracefully

#### UX Considerations
- **Entry Points**: Onboarding flow (required), Settings (add more accounts)
- **Key Interactions**: Tap to launch Plaid Link modal
- **Feedback Mechanisms**: Success confirmation, sync progress indicator
- **Error States**: Clear error messages with retry options

#### Out of Scope
- Manual transaction entry
- Bank connection via direct credentials (non-Plaid)
- Investment account tracking

---

### Feature: Leaky Bucket Selection

#### Overview
Users select 2-4 spending categories they want to track — their "leaky buckets." This focuses attention on high-impact areas rather than overwhelming with full financial data. The constraint is intentional: less is more.

#### User Story
**As a** new user,  
**I want to** choose which spending categories to track,  
**So that I can** focus on the areas where my money quietly disappears.

#### Acceptance Criteria

**Happy Path:**
- Given the user has connected their bank
- When they reach the category selection screen
- Then they see a curated list of common "leaky bucket" categories with clear icons
- And they can select 2-4 categories
- And they see example merchants for each category

**Validation:**
- Given the user tries to select fewer than 2 categories
- When they tap "Continue"
- Then they see: "Pick at least 2 categories to get started"

- Given the user tries to select more than 4 categories
- When they tap a 5th category
- Then the oldest selection is deselected with subtle animation

**Edge Cases:**

| Scenario | Expected Behavior |
|----------|-------------------|
| User wants a category not listed | Show "Other" option with ability to specify keywords |
| User wants to change categories later | Available in Settings at any time |
| No transactions in selected category | Show encouraging empty state: "No spending here yet this week" |

#### Priority
**Level**: P0

**Justification**: Core product differentiator — focused tracking vs. full financial picture.

#### Dependencies
- **Prerequisite Features**: Bank Account Connection
- **External Dependencies**: Plaid transaction categorization

#### Default Category Options
1. Food Delivery (Uber Eats, DoorDash, Skip, Instacart)
2. Coffee Shops (Starbucks, Tim Hortons, local cafes)
3. Amazon
4. Restaurants & Dining Out
5. Rideshare (Uber, Lyft)
6. Subscriptions & Streaming
7. Fast Food
8. Alcohol & Bars
9. Shopping (General retail)
10. Other (custom keywords)

#### UX Considerations
- **Entry Points**: Onboarding (required), Settings (modify)
- **Key Interactions**: Tap to select/deselect, drag to reorder priority
- **Feedback Mechanisms**: Visual checkmark, count indicator (2/4 selected)
- **Error States**: Minimum selection warning

#### Out of Scope
- Unlimited category selection
- Custom category creation beyond "Other"
- Sub-category breakdowns (MVP)

---

### Feature: Daily Evening Notification

#### Overview
A single push notification delivered each evening summarizing the day's spending in tracked categories. This is the core value delivery mechanism — passive awareness without requiring the user to open the app.

#### User Story
**As a** user,  
**I want to** receive a brief daily summary of my spending,  
**So that I can** stay aware without actively checking an app.

#### Acceptance Criteria

**Happy Path:**
- Given the user has spending in tracked categories today
- When it reaches their configured notification time (default 8 PM local)
- Then they receive a notification in the format:
  "Today: $[total] — [Category] $[amount], [Category] $[amount]. [Contextual insight]."

**Example notifications:**
- "Today: $47 — Uber Eats $32, Amazon $15. You're averaging $38/day this week."
- "Today: $0 in your tracked categories. 🎯"
- "Today: $12 — Coffee $12. That's 4 coffees this week."

**Validation:**
- Given the user has no spending in tracked categories today
- When notification time arrives
- Then they receive: "Today: $0 in your tracked categories. 🎯"

**Edge Cases:**

| Scenario | Expected Behavior |
|----------|-------------------|
| Transaction pending (not yet posted) | Include pending transactions with note |
| User in different timezone | Respect device timezone |
| Notification permissions denied | Prompt to enable with clear value proposition |
| Do Not Disturb enabled | Respect system DND settings |

#### Priority
**Level**: P0

**Justification**: Primary value delivery mechanism — the "product" users receive daily.

#### Dependencies
- **Prerequisite Features**: Bank Connection, Leaky Bucket Selection
- **External Dependencies**: Push notification service (APNs/FCM)

#### Technical Constraints
- Notifications must be generated server-side for accuracy
- Must handle timezone edge cases (travel, DST)
- Should batch-process all users efficiently

#### UX Considerations
- **Customization**: Notification time adjustable in settings (default 8 PM)
- **Frequency**: Once daily only — never more
- **Tone**: Neutral, informative, never judgmental
- **Length**: Must fit in collapsed notification view (~100 characters)

#### Notification Tone Guidelines
- ✅ "Today: $47 — Uber Eats $32, Amazon $15."
- ✅ "You've spent $156 on food delivery this week."
- ❌ "You overspent on food delivery again!"
- ❌ "Consider cutting back on Uber Eats."
- ❌ "You could save $200/month if you stopped..."

#### Out of Scope
- Real-time transaction notifications
- Multiple notifications per day
- Notification categories/channels

---

### Feature: Weekly Visual Summary

#### Overview
A single in-app screen showing the user's week at a glance. Visual, scannable, and designed to be consumed in under 30 seconds. This is the "Sunday reflection" moment.

#### User Story
**As a** user,  
**I want to** see a visual summary of my weekly spending,  
**So that I can** understand patterns and trends at a glance.

#### Acceptance Criteria

**Happy Path:**
- Given it's Sunday (or user opens summary manually)
- When the user opens the app or taps the weekly notification
- Then they see a single-screen summary containing:
  - Total spent in tracked categories this week
  - Breakdown by category (visual bar or pie)
  - Comparison to last week (simple up/down arrow with %)
  - Day-by-day mini visualization
  - Top 3 merchants in tracked categories

**Visual Elements:**
- Category breakdown: Horizontal stacked bar showing proportion
- Week comparison: Large number with green/red arrow
- Daily pattern: 7-dot visualization showing relative daily spend

**Edge Cases:**

| Scenario | Expected Behavior |
|----------|-------------------|
| First week (no prior data) | Show current week only, no comparison |
| No spending in tracked categories | Celebratory empty state |
| Single category selected | Simplify to merchant breakdown |

#### Priority
**Level**: P0

**Justification**: Core product experience — the weekly "mirror" moment.

#### Dependencies
- **Prerequisite Features**: Bank Connection, Leaky Bucket Selection, Daily Notifications
- **Data Requirements**: Full week of transaction data

#### UX Considerations
- **Entry Points**: Sunday push notification, app home screen
- **Key Interactions**: Tap categories for merchant detail
- **Scroll behavior**: No scroll required — single screen
- **Share**: Optional share image for accountability partners

#### Design Principles
1. **Glanceable**: Core insight visible without interaction
2. **Non-judgmental**: No red/negative framing of high spending
3. **Comparative**: Context through comparison, not absolute judgment
4. **Minimal**: No more than 5 data points visible at once

#### Out of Scope
- Detailed transaction list
- Multi-week historical views (P1)
- Custom date range selection
- Budget vs. actual comparisons

---

### Feature: Trend Analysis (Premium)

#### Overview
Premium feature showing spending trends over time — weekly, monthly, and rolling averages. Helps users see longer-term patterns beyond the weekly snapshot.

#### User Story
**As a** premium user,  
**I want to** see how my spending changes over time,  
**So that I can** understand if my awareness is leading to behavior change.

#### Acceptance Criteria

**Happy Path:**
- Given the user has 4+ weeks of data
- When they access the Trends screen
- Then they see:
  - Line chart of weekly spending by category (4-12 week view)
  - Rolling 4-week average
  - "Best week" and "Highest week" markers
  - Month-over-month comparison

**Edge Cases:**

| Scenario | Expected Behavior |
|----------|-------------------|
| Less than 4 weeks data | Show available data with note: "More insights coming as we gather data" |
| Category changed mid-period | Show data only for current categories, note historical change |

#### Priority
**Level**: P1

**Justification**: Key premium differentiator, but core value delivered without it.

#### Dependencies
- **Prerequisite Features**: All P0 features, minimum 4 weeks of data
- **Paywall**: Accessible only to premium subscribers

#### UX Considerations
- **Entry Points**: Premium tab, prompt after 4 weeks of free use
- **Interactions**: Swipe between time ranges, tap data points for detail
- **Empty State**: Clear path to premium upgrade

#### Out of Scope
- Predictive forecasting
- Custom date ranges
- Export functionality (separate P2 feature)

---

### Feature: Shared Category Tracking (Premium)

#### Overview
Allows two users to share visibility into specific spending categories. Each user sees the combined total for shared categories, enabling couples or accountability partners to have aligned awareness without surveillance.

#### User Story
**As a** user with a partner,  
**I want to** share visibility into specific spending categories,  
**So that** we can be aligned on shared financial awareness without monitoring each other.

#### Acceptance Criteria

**Happy Path:**
- Given User A invites User B to share "Dining Out" category
- When User B accepts the invitation
- Then both users see combined "Dining Out" total in their weekly summaries
- And neither user sees individual transaction details from the other

**Privacy Model:**
- Shared view shows: Combined category total only
- Shared view does NOT show: Individual transactions, individual amounts, merchant details

**Edge Cases:**

| Scenario | Expected Behavior |
|----------|-------------------|
| One user removes shared category | Other user notified, category returns to individual-only |
| Partner hasn't installed app | Invitation sent via SMS/email with download link |
| Different category names selected | Standardize to Plaid categories |

#### Priority
**Level**: P1

**Justification**: Valuable differentiation for couples segment, but not required for core individual use case.

#### Dependencies
- **Prerequisite Features**: All P0 features
- **Technical**: User account system, invitation flow

#### UX Considerations
- **Invitation flow**: Simple link-based sharing
- **Permission granularity**: Per-category opt-in
- **Disconnect flow**: Easy one-tap removal

#### Out of Scope
- Full financial transparency between partners
- Shared budgets or goals
- More than 2 users sharing

---

## 4. Functional Requirements

### User Flows

#### Flow: New User Onboarding
```
[Download App] → [Welcome Screen] → [Connect Bank (Plaid)] → [Select Categories (2-4)] → [Set Notification Time] → [Confirmation] → [Home Screen]
```

**Steps:**
1. User downloads app and opens to welcome screen explaining core value prop (3 screens max)
2. User taps "Get Started" and is presented with Plaid Link
3. User completes bank connection (may include MFA)
4. User selects 2-4 leaky bucket categories from curated list
5. User confirms notification time (default 8 PM, adjustable)
6. User sees confirmation screen with first notification preview
7. User lands on home screen (may be empty if no transactions yet today)

#### Flow: Daily Engagement
```
[Notification Received] → [Glance at notification] → [Optional: Open app] → [View today's detail]
                                                   → [Dismiss] → [End]
```

**Steps:**
1. User receives daily notification at configured time
2. User glances at notification content (no app open required)
3. Optional: User taps notification to see additional context
4. User dismisses notification and continues their day

#### Flow: Weekly Review
```
[Sunday Notification] → [Tap to open] → [View Weekly Summary] → [Optional: Tap category for detail] → [Close]
```

**Steps:**
1. User receives Sunday notification: "Your week in review is ready"
2. User taps notification to open weekly summary screen
3. User scans visual summary (under 30 seconds)
4. Optional: User taps a category to see merchant breakdown
5. User closes app, week complete

### State Management

| State | Trigger | Behavior |
|-------|---------|----------|
| No Account | App install | Show onboarding flow |
| Bank Connecting | Plaid Link initiated | Show connection progress |
| Bank Connected | Plaid success | Sync transactions, show category selection |
| Active | Onboarding complete | Show daily notifications, weekly summaries |
| Sync Error | Plaid connection lost | Prompt reconnection, show cached data |
| Premium | Subscription activated | Unlock trends, shared tracking |

### Data Validation Rules

| Field | Type | Rules | Error Message |
|-------|------|-------|---------------|
| Notification Time | Time | Valid 24-hour time | "Please select a valid time" |
| Categories Selected | Array | 2-4 items required | "Select 2-4 categories to continue" |
| Custom Category Keywords | String | 1-50 characters, alphanumeric | "Keywords must be 1-50 characters" |

### Integration Points

| System | Type | Purpose | Data Exchange |
|--------|------|---------|---------------|
| Plaid | REST API | Bank connection, transaction sync | Auth tokens → Transactions |
| APNs/FCM | Push SDK | Daily/weekly notifications | User ID → Push delivery |
| RevenueCat | SDK | Subscription management | User ID → Entitlements |
| Analytics (Mixpanel/Amplitude) | SDK | Usage tracking | Events → Dashboards |

---

## 5. Non-Functional Requirements

### Performance

| Metric | Requirement | Measurement |
|--------|-------------|-------------|
| App Launch Time | < 2 seconds (cold start) | Performance monitoring |
| Transaction Sync | < 30 seconds for initial sync | APM tracking |
| Notification Delivery | Within 5 minutes of scheduled time | Push analytics |
| Weekly Summary Load | < 1 second | Screen render timing |

### Scalability

| Dimension | MVP Target | 12-Month Target | Strategy |
|-----------|------------|-----------------|----------|
| Users | 1,000 | 100,000 | Serverless architecture |
| Daily Notifications | 1,000 | 100,000 | Batch processing, message queue |
| Transaction Volume | 50K/day | 5M/day | Async processing, caching |

### Security

| Requirement | Implementation |
|-------------|----------------|
| Authentication | Email/password + biometric, OAuth (Apple/Google) |
| Bank Credentials | Never stored — Plaid handles all credential management |
| Data Encryption | At rest: AES-256, In transit: TLS 1.3 |
| Token Storage | iOS Keychain / Android Keystore |
| Audit Logging | All data access logged with retention |

### Privacy

| Requirement | Implementation |
|-------------|----------------|
| Data Minimization | Store only transaction data needed for core features |
| User Control | Full data export and deletion available |
| Third-Party Sharing | Never sell or share transaction data |
| Compliance | CCPA, PIPEDA compliant |

### Accessibility

| Standard | Level | Requirements |
|----------|-------|--------------|
| WCAG | 2.1 AA | Full compliance |
| VoiceOver/TalkBack | Full | All screens accessible |
| Dynamic Type | Supported | Text scales with system settings |
| Color Contrast | 4.5:1 minimum | All text elements |

### Reliability

| Metric | Target |
|--------|--------|
| Uptime | 99.5% |
| Notification Delivery Rate | 99% |
| Data Accuracy | 99.9% (matching Plaid) |

---

## 6. UX Requirements

### Information Architecture

```
[Drift App]
├── Home (Today's Summary)
│   ├── Today's Total
│   ├── Category Breakdown
│   └── Quick Actions
├── Week (Weekly Summary)
│   ├── Visual Overview
│   ├── Category Details
│   └── Week Comparison
├── Trends (Premium)
│   ├── Line Charts
│   └── Historical Data
└── Settings
    ├── Connected Accounts
    ├── Categories
    ├── Notification Time
    ├── Shared Tracking
    └── Account/Subscription
```

### Progressive Disclosure Strategy

| Level | Content | Trigger |
|-------|---------|---------|
| 1 - Essential | Daily notification, weekly summary | Default (passive delivery) |
| 2 - On Request | Category merchant details, day breakdown | Tap to expand |
| 3 - Premium | Trends, projections, shared tracking | Subscription upgrade |

### Error Prevention

| Risk | Prevention Mechanism |
|------|---------------------|
| Bank disconnection | Proactive notification when re-auth needed |
| Wrong category selection | Preview of example merchants before confirming |
| Notification fatigue | Single notification per day, adjustable time |
| Data overwhelm | Hard limit of 4 tracked categories |

### Feedback Patterns

| Action Type | Feedback | Timing |
|-------------|----------|--------|
| Bank connected | Success animation + confetti | On completion |
| Category selected | Subtle haptic + checkmark | Immediate |
| Settings changed | Toast confirmation | Immediate |
| Week complete | Summary ready notification | Sunday |

### Empty States

| State | Message | Action |
|-------|---------|--------|
| First day (no spending) | "No spending in your tracked categories today. We'll let you know when something comes through." | None needed |
| First week (no data yet) | "Your first weekly summary is building. Check back Sunday!" | None needed |
| Category with no spending | "Nothing here this week. 🎯" | Celebrate the win |
| Trends (insufficient data) | "Trends unlock after 4 weeks. You're [X] days away." | Show progress |

### Core Design Principles

1. **Simplicity over features**: When in doubt, remove
2. **Passive over active**: Deliver value without requiring action
3. **Awareness over judgment**: Show the mirror, not the verdict
4. **Glanceable over detailed**: Optimize for 10-second consumption
5. **Calm over urgent**: Finance apps shouldn't stress you out

---

## 7. Risks and Gaps

### Known Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Plaid costs at scale | High | Medium | Negotiate volume pricing, optimize API calls |
| Notification fatigue | Medium | High | Single daily notification, easy customization |
| Bank connection reliability | Medium | High | Graceful degradation, cached data, re-auth flows |
| User confusion about categories | Medium | Medium | Example merchants, preview before selection |
| Low free-to-premium conversion | Medium | High | Strong premium value prop, trial period |
| Competitive response (banks add this) | Low | High | Move fast, build brand loyalty, focus on UX |

### Assumptions

| Assumption | Validation Method | Owner |
|------------|------------------|-------|
| Users want awareness without budgets | User interviews, MVP usage data | Product |
| Evening is the right notification time | A/B test notification times | Growth |
| 2-4 category limit is correct | User feedback, retention analysis | Product |
| Users will pay $4/month for trends | Pricing experiments | Growth |
| Plaid categorization is accurate enough | Data quality audit | Engineering |

### Open Questions

| Question | Impact | Deadline | Owner |
|----------|--------|----------|-------|
| Optimal default notification time? | Medium | Before launch | Product |
| Which categories to include by default? | Medium | Before launch | Product |
| Premium pricing ($3 vs $4 vs $5/month)? | High | Week 4 | Growth |
| Android vs iOS first? | Medium | Week 1 | Engineering |
| Brand name finalized? (Drift vs alternatives) | Low | Week 2 | Marketing |

### Dependencies

| Dependency | Type | Status | Risk if Delayed |
|------------|------|--------|-----------------|
| Plaid API access | External | Application submitted | Blocks all development |
| App Store approval | External | Not started | Delays launch 1-2 weeks |
| Push notification infrastructure | Internal | Not started | Core feature unavailable |
| Design system/UI kit | Internal | Not started | Slows development |

---

## 8. Appendix

### Glossary

| Term | Definition |
|------|------------|
| Leaky Bucket | A spending category where money "quietly disappears" through frequent, low-friction purchases |
| Awareness (vs. Budgeting) | Passive visibility into spending patterns without setting goals or limits |
| Reflective Notification | Information delivered after the fact (evening) rather than in-the-moment (interruptive) |

### Competitive Landscape

| Competitor | Approach | Why Drift is Different |
|------------|----------|----------------------|
| Mint (discontinued) | Full financial picture, budgets, goals | Overwhelming, requires active engagement |
| YNAB | Zero-based budgeting | High friction, methodology learning curve |
| Rocket Money | Subscription tracking, bill negotiation | Different focus (recurring vs. discretionary) |
| Copilot | Premium finance tracking | Expensive, feature-rich (opposite approach) |
| Bank apps | Transaction history | No insights, no awareness patterns |

### Technical Stack Recommendation

| Layer | Recommendation | Rationale |
|-------|---------------|-----------|
| Mobile | React Native or Flutter | Cross-platform efficiency for MVP |
| Backend | Node.js + PostgreSQL | Familiar stack, good Plaid SDKs |
| Infrastructure | Vercel/Railway or AWS | Serverless for cost efficiency at scale |
| Push Notifications | OneSignal or Firebase | Reliable, good free tier |
| Analytics | Mixpanel | Event-based, good for product analytics |
| Payments | RevenueCat | Handles iOS/Android subscription complexity |

### MVP Timeline Estimate

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| Phase 1: Foundation | 2 weeks | Plaid integration, basic transaction sync |
| Phase 2: Core Features | 3 weeks | Category selection, daily notifications, weekly summary |
| Phase 3: Polish | 2 weeks | Onboarding, settings, error handling |
| Phase 4: Beta | 2 weeks | TestFlight/internal testing, iteration |
| Phase 5: Launch | 1 week | App Store submission, soft launch |

**Total: ~10 weeks to MVP**

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | January 17, 2026 | Product Team | Initial draft |

---

*This PRD is a living document. Updates will be made as user research, technical discovery, and market conditions evolve.*
