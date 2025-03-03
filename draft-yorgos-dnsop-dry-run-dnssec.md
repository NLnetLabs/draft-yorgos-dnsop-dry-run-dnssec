%%%
Title = "dry-run DNSSEC"
abbrev = "dry-run-dnssec"
docname = "@DOCNAME@"
category = "std"
area = "Internet"
workgroup = "DNSOP Working Group"
date = @TODAY@

[seriesInfo]
name = "Internet-Draft"
value = "@DOCNAME@"
stream = "IETF"
status = "standard"

[[author]]
initials = "Y."
surname = "Thessalonikefs"
fullname = "Yorgos Thessalonikefs"
organization = "NLnet Labs"
[author.address]
 email = "yorgos@nlnetlabs.nl"
[author.address.postal]
 street = "Science Park 400"
 city = "Amsterdam"
 code = "1098 XH"
 country = "Netherlands"

[[author]]
initials="W."
surname="Toorop"
fullname="Willem Toorop"
organization = "NLnet Labs"
[author.address]
 email = "willem@nlnetlabs.nl"
[author.address.postal]
 street = "Science Park 400"
 city = "Amsterdam"
 code = "1098 XH"
 country = "Netherlands"

[[author]]
initials = "R."
surname = "Arends"
fullname = "Roy Arends"
organization = "ICANN"
[author.address]
 email = "roy.arends@icann.org"
%%%


.# Abstract

This document describes a method called "dry-run DNSSEC" that allows for
testing DNSSEC deployments without affecting the DNS service in case of DNSSEC
errors.
It accomplishes that by introducing new DS Type Digest Algorithms that when
used in a DS record,  referred to as dry-run DS, signal to validating resolvers
that dry-run DNSSEC is used for the zone.
DNSSEC errors are then reported with DNS Error Reporting, but any bogus
responses to clients are withheld.
Instead, validating resolvers fallback from dry-run DNSSEC and provide the
response that would have been answered without the presence of a dry-run DS.
A further EDNS option is presented for clients to opt-in for dry-run DNSSEC
errors and allow for end-to-end DNSSEC testing.


{mainmatter}


# Introduction

DNSSEC was introduced to provide DNS with data origin authentication and data
integrity.
This brought quite an amount of complexity and fragility to the DNS which in
turn still hinders general adoption.
When an operator decides to publish a newly signed zone there is no way to
realistically check that DNS resolution will not break for the zone.

Recent efforts that improve troubleshooting DNS and DNSSEC include Extended DNS
Errors [@!RFC8914] and DNS Error Reporting [@!RFC9567].
The former defines error codes that can be attached to a response as EDNS
options.
The latter introduces a way for resolvers to report those error codes to the
zone operators.

This document describes a method called "dry-run DNSSEC" that builds upon the
two aforementioned efforts and gives confidence to operators to adopt DNSSEC by
enabling production testing of a DNSSEC zone.
This is accomplished by introducing new DS Type Digest Algorithms.
The zone operator signs the zone and makes sure that the DS record published on
the parent side uses the specific DS Type Digest Algorithm.
Validating resolvers that don't support the DS Type Digest algorithms ignore it
as per [@!RFC6840, see, section 5.2].
Validating resolvers that do support dry-run DNSSEC make use of [@!RFC8914] and
[@!RFC9567] to report any DNSSEC errors to the zone operator.
If a DNSSEC validation error was due to dry-run DNSSEC, validation restarts by
ignoring the dry-run DS in order to give the real DNS/DNSSEC response to the
client.

This allows real world testing with resolvers that support dry-run DNSSEC
by reporting DNSSEC feedback, without breaking DNS resolution for the domain
under test.


# Terminology

The key words "**MUST**", "**MUST NOT**", "**REQUIRED**",
"**SHALL**", "**SHALL NOT**", "**SHOULD**", "**SHOULD NOT**",
"**RECOMMENDED**", "**NOT RECOMMENDED**", "**MAY**", and
"**OPTIONAL**" in this document are to be interpreted as described in
BCP 14 [@!RFC2119;@!RFC8174] when, and only when, they appear in all
capitals, as shown here.

real DS
: The actual DS record for the delegation.

dry-run DS
: The DS record with the special DS type digest algorithm that signals dry-run
  DNSSEC for the delegation.

dry-run zone
: A zone that is DNSSEC signed but uses a dry-run DS to signal the use of the
  dry-run DNSSEC method.

dry-run parent zone
: A zone that supports dry-run DNSSEC for its delegation, that is support for
  publishing the dry-run DS.

dry-run resolver
: A validating resolver that supports dry-run DNSSEC.

wet-run client
: A client that has opted-in to receive the actual DNSSEC errors from the
  upstream validating resolver instead of the insecure answers.


# Overview {#overview}

Dry-run DNSSEC builds upon three previous experiences namely DMARC [@!RFC7489],
Root Key Trust Anchor Sentinel [@!RFC8509] and Signaling Trust Anchor Knowledge
[@!RFC8145].
The former enabled email operators to verify their configuration with real
email servers by getting DMARC reports and understanding the impact on email
delivery their configuration would have before committing to enable DMARC.
Experience with the latter two showed that with only a small, up to date
resolver population, the signaling is already quite substantial.

Dry-run DNSSEC offers zone operators the means to test newly signed zones and
a turn-key action to conclude testing and commit to the tested DNSSEC records.
Operators that want to use dry-run DNSSEC SHOULD support [@!RFC9567] and have a
reporting agent in place to receive the error reports.

The only change from normal operations when signing a zone with dry-run
DNSSEC is to not publish the real DS record on the parent but publish the
dry-run DS record instead.
See (#signaling) for more information on the dry-run DS record itself, and
(#provisioning) on the parent-child communication for the dry-run DS record.

Validating resolvers that don't support the DS Type Digest algorithm ignore it
as per [@!RFC6840, see, section 5.2].
Validating resolvers that support dry-run DNSSEC are signaled to treat the
zone as a dry-run zone.
Validating resolvers that support dry-run DNSSEC SHOULD support [@!RFC9567] in
order to report possible errors back to the operators.

Valid answers as a result of dry-run validation yield authentic data (AD)
responses and clients that expect the AD flag can already benefit from the
transition.

Invalid answers yield the response that would have been answered when no
dry-run DS would have been present in the parent instead of SERVFAIL.
For zones that had only dry-run DS RRs in the parent, an invalid answer yields
an insecure response.
This is not proper data integrity but the delegation SHOULD NOT be considered
DNSSEC signed at this point.
For zones that had other non dry-run DS RRs in the parent, validation MUST
restart by using those RRs instead.

[@!RFC9567] is used for invalid answers and it can generate reports
for errors in dry-run DNSSEC zones.
This helps with monitoring potential DNS breakage when testing a DNSSEC
configuration for a zone.
This is also the main purpose of dry-run DNSSEC.

The newly signed zone is publicly deployed but DNSSEC configuration errors
cannot break DNS resolution yet.
DNS Error Reports can pinpoint potential issues back to the operator.
When the operator is confident that the DNSSEC configuration under test does
not introduce DNS breakage, the turn-key action to conclude testing and commit
to the singed zone is to replace the dry-run DS with the real DS record on the
parent zone.

## Use cases {#use-cases}

Dry-run DNSSEC can be used to test different DNSSEC scenarios.
From adopting DNSSEC for a zone, which is the main goal of this document, to
testing experimental DNSSEC configurations and key rollovers.
Dry-run resolvers generate error reports in case of validation errors in
dry-run zones and they fallback to the non-dry-run part of the zones to
complete validation.

### DNSSEC adoption {#dnssec-adoption}

This use case tests DNSSEC adoption for an insecure zone.
The zone is signed and a single dry-run DS record is published on the parent.
Validation errors yield error reports but invalid answers do not result in
SERVFAIL responses to clients.

### Experimental DNSSEC configuration {#experimental-dnssec-configuration}

This use case can test a completely different DNSSEC configuration for an
already signed zone.
The zone is doubly signed and there are at least two DS RRs in the parent zone.
Dry-run resolvers try to use the dry-run part of the zone.

### Key rollover {#key-rollover}

As with the experimental case above, but for the benefit of testing a key
rollover before actually committing to it.
The rollover test can be initiated from the zone operator by introducing the
real DS also as a dry-run DS as the first step of the test.
Normal key rollover procedures can continue by introducing the new key as
another dry-run DS record.
Dry-run resolvers try to use the dry-run part of the zone which now resembles
a key rollover.
When testing was successful, the key rollover procedure can be repeated in the
real DS space with the same keys.

A special key rollover case could be for the root.
This can be made possible by specifying the dry-run DS Digest Type in the
<DigestType> element in http://data.iana.org/root-anchors/root-anchors.xml or a
different way of indicating in the xml file.

## Fallback behavior {#fallback}

In case of validation errors with the dry-run DSes, dry-run resolvers fallback
to the real DSes and restart validation.

If there are no real DSes, as in the DNSSEC adoption use case, the zone
is resolved as insecure.

If there are real DSes, as in the experimental DNSSEC configuration and key
rollover use cases, the zone is validated based on them which may or may not
lead to further validation errors depending on the real DNSSEC status of the
zone.

Note that dry-run fallback validation can lead to increased workload which is
discussed further in (#security-workload).

## NOERROR report {#no-error}

Dry-run DNSSEC relies on DNS Error Reporting [@!RFC9567] to report resolution
errors back to the zone operators.
DNS Error Reporting solely addresses the reporting of DNS errors but it does
not give any guarantees that DNS Error Reporting aware resolvers are resolving
the zone.
This raises a concern especially for dry-run DNSSEC where absence of error
reports needs to translate to a positive signal that no DNSSEC errors were
encountered.

To solve this, dry-run DNSSEC introduces the NOERROR report.
The NOERROR report is sent from the resolver when no error was encountered
during dry-run DNSSEC validation and notifies the reporting agent of the
resolver's presence.

As with [@!RFC9567, see, section 4] the resolver will cache the reporting agent
reply and dampen the number of NOERROR report queries.

The NOERROR report is using the Extended DNS Error code TBD_no.

### Constructing the NOERROR Query {#no-error-query}
The QNAME for the NOERROR report query follows the same semantics as with
[@!RFC9567, see, section 6.1.1] and is constructed by concatenating the
following elements:

- A label containing the string "_er".

- The decimal value "0" in a single DNS label as the QTYPE is not relevant for
  the NOERROR report.

- The list of non-null labels representing the apex of the query name that
  triggered this report.

- The decimal value of TBD_no in a single DNS label as the Extended DNS Error.

- A label containing the string "_er".

- The agent domain. The agent domain as received in the EDNS0 Report-Channel
  option set by the authoritative server.

As with [@!RFC9567, see, section 6.1.1] if the QNAME of the report query
exceeds 255 octets, it MUST NOT be sent.

The apex is specifically used as the query name for resolvers to only send one
NOERROR report (if applicable) per zone and for the monitoring agents to
differentiate between different zones they are configured with.

## Opt-in end-to-end DNSSEC testing {#opt-in}

For further end-to-end DNS testing, a new EDNS0 option code TBD_w (Wet-Run
DNSSEC) is introduced that a client can send along with a query to a validating
resolver.
This signals dry-run resolvers that the client has opted-in to DNSSEC errors
for dry-run zones.
Dry-run resolvers that support opt-in MUST respond with the dry-run DNSSEC
error if any and MUST attach the same EDNS0 option code TBD_w in the response
to mark the error response as coming from a dry-run zone.

Dry-run resolvers that support opt-in MUST cache the DNSSEC status of the
dry-run validation next to the actual DNSSEC status.
This enables cached answers to both regular and opt-in clients, similar to
cached answers to clients with and without the CD flag set.

Additional Extended DNS Errors can still be attached in the error response by
the validating resolver as per [@!RFC8914].

Dry-run resolvers that do not support opt-in MUST ignore the TBD_w EDNS0
option and MUST NOT attach the TBD_w EDNS0 option code in their replies.

# Signaling {#signaling}

Signaling to dry-run resolvers that a delegation uses dry-run DNSSEC happens
naturally with the DS record returned from the parent zone by specifying new
DS Digest Type Algorithm(s).

Each algorithm has a potential dry-run equivalent.
This can be realised by either burning a bit in the DS Digest Type Algorithm
(the most significant bit) so that all current and future algorithms have a
dry-run DNSSEC equivalent, or by explicitly specifying algorithms for select
current and future algorithms.
The convention for this document is to only specify a new one for SHA-256 at
the moment; this will likely change in a future version.

Resolvers that do not support dry-run DNSSEC and have no knowledge of the
introduced DS Digest Type Algorithms ignore them as per
[@!RFC6840, see, section 5.2].

## Discussion from IETF 114

**Note to the RFC Editor**: please remove this entire section before publication.

This is addressed feedback as a result of IETF 114. We keep it here for future
reference while the document is advancing.

### Burn a bit for dry-run DS Digest Type Algorithms

- Viktor Dukhovni: 
  - Saner than variable variant.
  - Hash algorithms are introduced exceedingly rarely, symmetric hashes are
    very stable.
  - No evidence that SHA2 will be compromised in the next 100 years; we may
    have SHA3 at some point but little demand.

- Peter Thomassen:
  - Better to sacrifice a bit than variable length. Also for post quantum
    crypto, in response to Paul Hoffman below, even if keys are large the hash
    value will have a constant length.

- Libor Peltan: (mailing list)
  - Only a few code points in use now, it seems viable.

### Use a single DS Digest Type Algorithm for dry-run

- Need to encode the actual algorithm and data in the DS record; results in
  variable length DS record for a single algorithm.

- May hinder adoption due to EPP checks/requirements (known record length for
  each algorithm).

- Mark Andrews:
  - Variable length will be needed for private algorithm types so we may as
    well support it here.

- Paul Hoffman:
  - Recommends going to variable length to pave the way for post quantum crypto
    and the surprising length it may need.


# Provisioning {#provisioning}

This section discusses the communication between a dry-run DNSSEC zone and the
parent domain and the procedures that need to be in place in order for the
parent to publish a dry-run DS record for the delegation.
Most of the burden falls with the parent zone since they have to understand the
delegation's intent for use of dry-run DNSSEC.
If the parent does not accept DS records, they need to provide a means so that
the child can mark the provided DNSKEY(s) as dry-run DNSSEC.
This can be achieved either by a flag on the parent's interface, or their
willingness to accept and inspect DS records that accompany DNSKEYs for use of
the DRY-RUN DS Type Digest Algorithm.
The case of CDS/CDNSKEY is discussed below.

## Parent zone records {#parent-zone-records}

The only change that needs to happen for dry-run DNSSEC is for the parent to be
able to publish the dry-run DS record.
If the parent accepts DS records from the child, the child needs to provide the
dry-run DS record.
If the parent does not accept DS records and generates the DS records from the
DNSKEY, support for generating the dry-run DS record, when needed, should be
added to the parent if dry-run DNSSEC is a desirable feature.

When the child zone operator wants to complete the DNSSEC deployment, the
parent needs to be notified for the real DS record publication.

### CDS and CDNSKEY Consideration {#cds-cdnskey-consideration}

CDS works as expected by providing the dry-run DS content for the CDS record.
CDNSKEY cannot work by itself; it needs to be accompanied by the aforementioned
CDS to signal dry-run DNSSEC for the delegation.
Thus, parents that rely only on CDNSKEY need to add support for checking the
accompanying CDS record for the DRY-RUN DS Type Digest Algorithm and generating
a dry-run DS record if such a record is encountered.

Operators of a dry-run child zone are advised to publish both CDS and CDNSKEY
so that both cases above are covered.


# Security Considerations {#security}

## DNSSEC status {#security-dnssec}

For the use case of DNSSEC adoption, dry-run DNSSEC disables one of the
fundamental guarantees of DNSSEC, data integrity.
Bogus answers for expired/invalid data will become insecure answers providing
the potentially wrong information back to the requester.
This is a feature of this proposal but it also allows forged answers by third
parties to affect the zone.

This should be treated as a warning that dry-run DNSSEC is not an end solution
but rather a temporarily intermediate test step of a zone going secure.

Thus, a dry-run only zone (only dry-run DSes on the parent) SHOULD NOT be
considered as DNSSEC signed since it does not offer all the DNSSEC guarantees.

## Error reporting {#security-error-report}

Since dry-run DNSSEC relies heavily on DNS Error Reporting [@!RFC9567], the
same security considerations about the generated error reports apply here as
well.
Especially the use of TCP or DNS Cookies for the reports, which can be enforced
by the monitoring agent to make it harder to falsify the source address of
error reports.

## Workload increase {#security-workload}

Dry-run resolvers need to do some extra work when encountered with a validation
failure in a dry-run zone.
They would need to send a DNS Error Report out and restart validation ignoring
the dry-run DSes of the zone.

Restarting the validation can lead to double the validation effort for use
cases where the zone was already using DNSSEC, i.e., real DSes next to dry-run
DSes.
Dry-run resolver implementations need to consider this and allow for the same
validation limits regardless if the validation is for a real DNSSEC or a
dry-run DNSSEC zone, or a zone combining both.

Keeping (and resetting) the same validation limits is crucial for failure
reporting as it will realistically reflect the same behavior (and fail for the
same reasons) as with non-dry-run resolvers.
Furthermore, not imposing different limits on a dry-run resolver will not
hamper the real DNSSEC part of the zone when fallback from dry-run needs to
happen.
The real DNSSEC part of the zone will have the chance to validate under the
same workload limits and any previous dry-run validation workload will not
result in manifested DNSSEC errors due to premature exhaustion of validation
limits for example.

Thus, on dry-run validation failures the validation workload limits MUST be
reset and allow for the same workload limits when restarting validation.

# IANA Considerations

## DRY-RUN DS Type Digest Algorithm

This document defines a new entry in the "Delegation Signer (DS) Resource
Record (RR) Type Digest Algorithms" registry:

Value    | Digest Type     | Status   | Reference
--------:|-----------------|----------|----------------
TBD_ds   | SHA-256 DRY-RUN | OPTIONAL | [this document]

## NOERROR Extended DNS Error

This document defines a new entry in the "Extended DNS Error Codes"
registry on the "Domain Name System (DNS) Parameters" page:


INFO-CODE | Purspose            | Reference
---------:|---------------------|----------------
TBD_no    | NOERROR reporting   | [this document]

## Wet-Run EDNS0 Option

This document defines a new entry in the "DNS EDNS0 Option Codes (OPT)"
registry on the "Domain Name System (DNS) Parameters" page:


Value     | Name           | Status   | Reference
---------:|----------------|----------|----------------
TBD_wet   | Wet-Run DNSSEC | Optional | [this document]


# Acknowledgements

Martin Hoffmann contributed the idea of using the DS record of an already
signed zone also as a dry-run DS in order to facilitate testing key rollovers.


{backmatter}


# Implementation Status

**Note to the RFC Editor**: please remove this entire section before publication.

In the following implementation status descriptions, "dry-run DNSSEC" refers
to dry-run DNSSEC as described in this document.

None yet.


# Change History

**Note to the RFC Editor**: please remove this entire section before publication.

* draft-yorgos-dnsop-dry-run-dnssec-00

> Initial public draft.

* draft-yorgos-dnsop-dry-run-dnssec-01

> Document restructure and feedback incorporation from IETF 113.

* draft-yorgos-dnsop-dry-run-dnssec-02

> Document restructure and feedback incorporation from IETF 114; mainly:

> Use explicit dry-run algorithm types for DS.

> Introduce NOERROR reporting.

* draft-yorgos-dnsop-dry-run-dnssec-03

> Shape up NOERROR reporting.

> No need for exclusive NOERROR signal from upstream; existence of dry-run suffices.

> Ask for NOERROR Extended DNS Error.

> Remove most IETF 114 feedback sections for better flow of the document; kept the discussion about signaling.

> Add security considerations for increased validation workload.

> Add an explicit fallback behavior section.
