+++
title = "Length Beats Complexity: Rethinking Password Rules"
date = 2026-05-28T00:00:00+09:00
draft = false
tags = ["security", "authentication", "password", "nist", "system-design"]
+++

While designing user authentication for a new system, my hand stopped for a moment.

"Passwords must be at least 8 characters and include at least 3 of: uppercase letters, lowercase letters, numbers, and special characters." — this sentence was so familiar that I had never once questioned it. Nearly every site has a rule shaped like this, and I was about to copy that shape verbatim. But a line I had seen somewhere came back to me. **"The person who created the password complexity rules said he now regrets them."** I went back to check whether that was really said, and while I was at it, I also pulled together where current recommendations actually stand. To put the conclusion first: the rule we use as a matter of course is no longer recommended.

## The Retrospective From the Person Who Started It

The starting point for complexity rules was Appendix A of SP 800-63, published by the U.S. NIST in 2003. The person who wrote that appendix was Bill Burr. Mixing uppercase and lowercase letters, numbers, and special characters, and changing them periodically — the skeleton we now use so habitually — came straight out of this document.

In a 2017 Wall Street Journal interview, Burr said this.

> "Much of what I did I now regret."

He was saying he now regrets much of what he did. At the time he had almost no actual user data, so he had no choice but to lean heavily on a white paper from the 1980s when writing the guidance, and he even went so far as to use the phrase "barking up the wrong tree."

The reason complexity rules are wrong is simple. People produce variations that satisfy the rule while staying easy to remember. When `password` gets blocked, they move to `Password1!`. They swap `a` for `@`, tack `123` onto the end, and append `2024` to the company name. Attackers already know these human habits. In the end, complexity rules force users to be creative, but human creativity flows in predictable directions.

## NIST's Current Position — Length First, Complexity Forbidden

NIST made its position clear when it published SP 800-63 Revision 4 in July 2025. The normative language in the section that deals with passwords (SP 800-63B) reads as follows.

> "Verifiers and CSPs **SHALL** require passwords that are used as a single-factor authentication mechanism to be a minimum of **15 characters** in length."

When a password is used as a single factor, it must be at least 15 characters. Only when it is used as one factor in multi-factor authentication (MFA) is a minimum of 8 characters allowed.

> "Verifiers and CSPs **SHOULD** permit a maximum password length of at least **64 characters**."

The maximum length should allow at least 64 characters. The point is that the system must not block the space needed to use a long passphrase.

And this is the key clause.

> "Verifiers and CSPs **SHALL NOT** impose other composition rules (e.g., requiring mixtures of different character types) for passwords."

You **SHALL NOT** impose complexity requirements such as mixing character types. `SHALL NOT` is the strongest prohibition in NIST's normative language. It is not a recommendation against — it is a prohibition.

Periodic change has likewise been settled as prohibited.

> "Verifiers and CSPs **SHALL NOT** require subscribers to change passwords periodically."

The one caveat is that a forced change is required if there is evidence of compromise.

In summary, NIST's new recommendation comes down to these five lines.

- Minimum length for single-factor authentication is 15 characters.
- Maximum length must allow at least 64 characters.
- Forcing character-type combinations is prohibited.
- Forcing periodic change is prohibited.
- Checking against a blocklist (commonly used, expected, or compromised passwords) is mandatory.

The blocklist check ultimately means "no matter how long a user makes it, a common string like `password12345678` must be blocked." The combination of length + blocklist replaces complexity.

## Why Complexity Rules Collapsed

There isn't a single reason complexity fell apart. Three separate facts work at the same time.

### 1. Length Is Already Mathematically Stronger

From the perspective of a brute-force attack by a cracking program, security is the number of possible combinations (entropy). Even in that math, complexity does not beat length.

| Condition | Possible combinations | Entropy |
|------|---------------|---------|
| 8 chars + all 95 character types | 95⁸ ≈ 6.6 × 10¹⁵ | ~52.6 bits |
| 12 chars + 26 lowercase letters | 26¹² ≈ 9.5 × 10¹⁶ | ~56.4 bits |
| 16 chars + 26 lowercase letters | 26¹⁶ ≈ 4.3 × 10²² | ~75.2 bits |

Adding one character to the length has a bigger effect than adding one character type. Length sits in the exponent, while character type sits in the base. In other words, the intuition that "removing complexity makes it weaker" is itself wrong. Length alone can make it stronger.

### 2. Real Attacks Aren't Brute Force — They Target Human Patterns

This is the real heart of it. Real-world password cracking does not sweep the entire 95⁸ space. It only tries **the patterns a human is likely to create**. This is called a rule-based dictionary attack, and it is exactly what a tool like `hashcat` does best.

The problem is that the way users satisfy a "3 of letters/numbers/special characters, 8 characters" rule is astonishingly predictable.

- Only the first letter capitalized: `Password1!`, `Welcome24@`
- Letter → symbol substitution (leet speak): `P@ssw0rd`, `S3cr3t!`
- Word + year: `Company2024!`
- Season + year: `Spring2024!`, `Summer25!`

These patterns are already cataloged in hashcat's rulesets (`best64.rule`, `dive.rule`, and so on). As a result, a large share of 8-character passwords that satisfy complexity rules are cracked in offline attacks within minutes to hours.

The 95⁸ theoretical space that complexity rules promised is not actually 95⁸. It shrinks to the narrow set of patterns users actually inhabit. **Attackers aim precisely at that narrowed-down slice.** Complexity rules promised to increase security, but in the end they narrowed the user's choice space and built a hunting ground for attackers.

### 3. The Burden Comes Back as a Different Weakness

Complexity rules greatly increase a person's cognitive burden. Unable to bear that burden, people adapt like this.

- They write it down on paper, in a notepad, or in a phone memo.
- They reuse one password across every site.
- Instead of using a password manager, they rotate through one or two memorable patterns.

Reusing the same password is especially fatal. If one site is breached, the same password is immediately tried against other sites — a credential stuffing attack becomes possible. The starting point of security is no longer one line of password but the union of the weak links across the user's entire digital footprint.

The reason NIST explicitly allows paste is in the same vein. Blocking paste effectively blocks password manager use, and then users end up drifting toward reusing the same password.

### So Length Is Honest

Length is honest. Complexity is not. The 95⁸ space that complexity rules create shrinks down into the user's predictable patterns, but the 26¹² space that length creates naturally encompasses even natural-language passphrases a user can memorize. That is why a passphrase like `correct-horse-battery-staple` is both safer and easier to remember than `P@ssw0rd!`.

Complexity rules came from good intentions. They were simply created without data on how humans actually satisfy them. Now the data has accumulated, and the data shows that this rule worked the opposite of its intent.

## Korean Regulations — Still a Complexity + Length Combination

So how far have Korea's recommendations come? The conclusion is "they haven't caught up yet."

The line of administrative rules with enforcement power is as follows.

- Personal Information Protection Act, Article 29 (Duty of Safety Measures)
- Enforcement Decree of the Personal Information Protection Act, Article 30 (Measures to Ensure the Safety of Personal Information)
- Standards for Measures to Ensure the Safety of Personal Information (Personal Information Protection Commission notification), Article 4 (Management of Access Rights), Paragraph 5

The text of Article 4, Paragraph 5 reads as follows.

> "A personal information controller shall establish and apply password creation rules so that personal information handlers or data subjects can set and follow secure passwords."

The provision itself is a general obligation to "establish and apply creation rules." The specific recommended content sits as an "example" in the Personal Information Protection Commission's commentary (published October 2024, revised as Notification No. 2025-9 and effective October 31, 2025). That example reads as follows.

- At least 10 characters: a combination of **2 or more** of uppercase letters, lowercase letters, numbers, and special characters
- At least 8 characters: a combination of **3 or more** of uppercase letters, lowercase letters, numbers, and special characters
- Avoid sequential numbers (`12345678`), phone numbers, well-known words (`love`, `happy`), and keyboard-adjacent strings (`qwer`)
- Change at least every 6 months

Separately, KISA's "Guide to Selecting and Using Passwords" (established 2008, revised June 2019) follows the same skeleton.

In other words, Korea's recommendations still rest on a complexity basis. But two things are worth noting together.

First, the body of the commentary explicitly carries the caveat that **"the minimum password length may increase as technology advances."** That is, the publisher itself acknowledges that the example above is not a permanent standard but a point-in-time recommendation.

Second, what the notification's text requires is "establishing and applying creation rules," not "the commentary's example itself." The commentary is explicitly labeled an "example." It is not a violation of a legal obligation for a controller to apply a different security policy with reasonable grounds (for example, a longer length floor + blocklist + compromise-based forced change). The controller simply needs to be able to explain "why that policy is secure" during a regulator's inspection.

## So How Do We Design Our System

For the system I'm currently designing, I'm settling on the following.

- Set the minimum password length for single-factor authentication to **12 characters**. NIST's 15 characters is the most conservative bar, but considering the average input habits of Korean users, I start at 12. Once the system stabilizes, I'll raise it to 14–15.
- When used as one factor in multi-factor authentication, set the minimum to 8 characters.
- Allow a maximum length of **at least 64 characters**. Don't block long passphrases.
- **Don't force** character-type combinations. Remove the "mix uppercase, lowercase, numbers, and special characters" copy from the input field, and leave only "please enter at least 12 characters" instead.
- **Don't force** periodic change. Trigger a forced change only for accounts where evidence of compromise has been confirmed.
- Make the blocklist check mandatory. Include the Have I Been Pwned Pwned Passwords dataset, service-name variations, and frequently used in-house passwords.
- **Allow paste** in the password input field. Don't block password manager use.

My compliance position regarding the "Standards for Measures to Ensure the Safety of Personal Information" is framed as follows. The "establishing and applying password creation rules" required by Article 4, Paragraph 5 of the notification is satisfied. Instead of the commentary's 8-char + 3-type / 10-char + 2-type example, I adopted a policy of 12+ characters + blocklist check + compromise-based forced change, grounded in NIST SP 800-63B Rev. 4. I document in the policy that the combination of a length floor and a blocklist check provides safety equal to or greater than forced complexity.

## Closing

Password complexity rules started from good intentions, but as data accumulated in the meantime they lost their usefulness. It has now become clear that length is honest and complexity is not.

From the standpoint of designing a new system, taking a moment to re-verify a source rather than copying a familiar rule turns out to be surprisingly rewarding. If you can swap a policy that drives users to write passwords down on paper for one that doesn't — at the same cost — that is not a small change.
