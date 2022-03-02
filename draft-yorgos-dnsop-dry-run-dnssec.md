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
 email = "george@nlnetlabs.nl"
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
%%%


.# Abstract

This document describes a method called "dry-run DNSSEC" that allows for
testing DNSSEC deployments without affecting the DNS service in case of
configuration errors. It accomplishes that by introducing a new DS Type Digest
Algorithm that signals to validating resolvers that dry-run DNSSEC is used for
the zone. DNSSEC errors are then reported with DNS Error Reporting, but the
bogus answer is withheld and instead resolvers fallback from dry-run DNSSEC and
provide the answer they would normally produce for the zone. Further options
are presented for testing key rollovers with this method and an option for
clients to opt-in for dry-run DNSSEC errors and allow for end-to-end DNSSEC
testing.


{mainmatter}


# Introduction

DNSSEC was introduced to provide DNS with data origin authentication and data
integrity. This introduced quite an amount of complexity and fragility to the
DNS which in turn still hinders general adoption. When an operator decides to
publish a newly signed zone there is no way to realistically check that DNS
will not break for the zone.

This document describes a method called "dry-run DNSSEC" that gives confidence
to operators to adopt DNSSEC by introducing a new special DS Type Digest
Algorithm. Resolvers that don't support the algorithm continue to treat the
delegation as insecure [@RFC6840, see, section 5.2]. Validating resolvers are
signaled to treat the delegation as being in an intermediate test step for
DNSSEC. Valid answers yield authentic data (AD) responses. Clients that expect
the AD flag can already profit from the transition. Invalid answers instead of
SERVFAIL yield the insecure data. This is of course not proper data integrity
but the delegation should not be considered DNSSEC signed at this point.
Together with DNS Error Reporting support, which is essential for dry-run
DNSSEC, DNSSEC health is reported back to the operator.

The signed zone is publicly deployed but DNSSEC configuration errors cannot
break DNS resolution yet. DNSSEC health feedback can pinpoint potential issues
back to the operator. When the operator is confident that the DNSSEC adoption
does not introduce DNS breakage, the real DS record can be published on the
parent zone and that concludes the actual DNSSEC deployment.

Dry-run DNSSEC can further be used on already singed zones to test key
rollovers. In this case a dry-run DS record for the future key is used next to
the current DS record which itself needs to be also presented in the dry-run
format. Validating resolvers that understand dry-run DNSSEC first try to
validate with a dry-run DS before falling back to real DSes.

For further end-to-end DNS testing, a new EDNS0 option code is introduced that
a client can send along with a query to a validating resolver. This signals
validating resolvers that the client has opted-in to DNSSEC errors for dry-run
delegations. The resolver still uses DNS Error Reporting for dry-run errors
but instead of the insecure answer it provides the client with the SERVFAIL
answer, same as with actual DNSSEC. These clients are called "wet-run clients".


# Terminology

The key words "**MUST**", "**MUST NOT**", "**REQUIRED**",
"**SHALL**", "**SHALL NOT**", "**SHOULD**", "**SHOULD NOT**",
"**RECOMMENDED**", "**NOT RECOMMENDED**", "**MAY**", and
"**OPTIONAL**" in this document are to be interpreted as described in
BCP 14 [@!RFC2119] [@!RFC8174] when, and only when, they appear in all
capitals, as shown here.

dry-run DS
: The DS record with the special DS type digest algorithm that signals dry-run
  DNSSEC for the delegation.

real DS
: The actual DS record for the delegation. Replaces the dry-run DS to complete
  DNSSEC deployment.

dry-run zone
: A zone that is DNSSEC signed but uses a dry-run DS to signal the use of the
  dry-run DNSSEC method.

wet-run client
: A client that has opted-in to receive the actual DNSSEC errors from the
  upstream validating resolver instead of the insecure answers.


# Description {#description}

TODO

## The dry-run DS structure {#dry-run-structure}

The dry-run DS record is a normal DS record with updated semantics to allow for
dry-run signaling to a validating resolver. The DS Type Digest Algorithm value
MUST be TBD (DRY-RUN). The first octet of the DS Digest field contains the
actual Type Digest Algorithm, followed by the actual Digest:


                        1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |           Key Tag             |  Algorithm    |    DRY-RUN    |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   | Digest Type   |                                               /
   +-+-+-+-+-+-+-+-+            Digest                             /
   /                                                               /
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+


Validating resolvers encountering such a DS record will know to mark this
delegation as dry-run DNSSEC and extract the actual Type Digest Algorithm and
Digest from the dry-run DS Digest field.

Validating resolvers that have no knowledge for the DRY-RUN DS Type Digest
Algorithm MUST disregard the DS record as per [@RFC6840, see, section 5.2].

## DNSSEC Error Reporting {#dnssec-error-reporting}

The main purpose of the dry-run DNSSEC proposal is to be able to monitor
potential DNS breakage when adopting DNSSEC for a zone. The main tool to do
that is DNSSEC Error Reporting [citation needed].

Operators that want to use dry-run DNSSEC SHOULD support DNSSEC Error Reporting
and have a reporting agent in place to receive the error reports.

Implementations that support dry-run DNSSEC MUST also support DNSSEC Error
Reporting and report any DNSSEC errors for the dry-run zone to the
designated report agent.

## Parent zone records {#parent-zone-records}

The only change that needs to happen for dry-run DNSSEC is for the parent to
be able to publish the dry-run DS record. If the parent accepts DS records from
the child, the child needs to provide the dry-run DS record. If the parent does
not accept DS records and generates the DS records from the DNSKEY, support for
generating the dry-run DS record when needed should be added to the parent if
dry-run DNSSEC is a desirable feature.

When the child zone operator wants to complete the DNSSEC deployment, the
parent needs to be notified for the real DS record.

### CDS and CDNSKEY Consideration {#cds-cdnskey-consideration}

CDS works as expected by providing the dry-run DS content for the CDS
record. CDNSKEY cannot work by itself; it needs to be accompanied by the
aforementioned CDS to signal dry-run DNSSEC for the delegation. Thus, parents
that rely only on CDNSKEY need to add support for checking the accompanying CDS
record for the DRY-RUN DS Type Digest Algorithm and generating a dry-run DS
record.

Operators of a dry-run child zone are advised to publish both CDS and
CDNSKEY so that both cases above are covered.

## dry-run DS and real DS coexistence {#dry-run-realDS-coexistence}

TODO
tldr:
for example testing key rollover.

* For ease of implementation and DoS prevention validators SHOULD pick a DS and
  DNSKEY pair they understand from both the dry-run and real pool of available
  DSes.
* If dry-run DSes are present, the validator MUST first consider those.
* If real DS is picked by validator, carry on.
* If dry-run DS is picked,
    * If everything OK, secure.
    * If something not OK, should report and fallback to real DS. No insecure
      answers for this one. It guarantees that the DNSSEC of the zone is not
      altered.
    * If going back to real DS, the real DS is now cached and no EDER reports
      for the same dry-run DS should be generated.

## wet-run clients {#wet-run-clients}

Wet-run clients are clients that send the EDNS0 option code TBD (Wet-Run
DNSSEC) when querying a validating resolver. These clients opt-in to receive
error responses in case of DNSSEC errors in a dry-run zone. They allow for
end-to-end DNSSEC testing in a controlled environment.

Validating resolvers that recognise the option MUST respond with the error that
they would normally respond for a DNSSEC zone and MUST attach the same EDNS0
option code TBD in the response to mark the error response as coming from a
dry-run zone.

Additional Extended DNS Errors can also be attached in the error response by
the validating resolver as per [@!RFC8914].


# Implementation Notes {#implementation-notes}

TODO
tldr; validating resolvers need to keep an additional DNSSEC status for cached
records that notes the DNSSEC status for the dry-run part. Responses can then
be provided based on the Wet-Run DNSSEC EDNS0 option.


# Security Considerations {#security}

Dry-run DNSSEC disables one of the fundamental guarantees of DNSSEC, data
integrity. Bogus answers for expired/invalid data will become insecure
answers providing the potentially wrong information back to the requester. This
is a feature of this proposal but it also allows forged answers by third
parties to still affect the zone. This should be treated as a warning that
dry-run DNSSEC is not an end solution but rather a temporarily intermediate
test step of a zone going secure.

Parent zones that provide signed delegations to child zones should be aware
that by using dry-run DNSSEC (e.g., testing a key roll to a stronger algorithm
key) they risk the DNSSEC status of the child zones. If the trust chain becomes
invalid between parent and child because of dry-run DNSSEC the child zone will
be treated as insecure.


# IANA Considerations

## A New Wet-Run EDNS0 Option

This document updates the IANA registry for EDNS0 options, currently called
"DNS EDNS0 Option Codes (OPT)". The following entry has been added:

Value          TBD
Name           Wet-Run DNSSEC
Status         Standard
Reference      This document

## A New DRY-RUN DS Type Digest Algorithm

This document updates the IANA registry for digest types in DS records,
currently called "Delegation Signer (DS) Resource Record (RR) Type Digest
Algorithms".  The following entry has been added:

Value          TBD
Digest Type    DRY-RUN
Status         OPTIONAL (MANDATORY?)


# Acknowledgements

This document is based on an idea by Yorgos Thessalonikefs and Willem Toorop.
Roy Arends contributed the structure of the dry-run DS for the digest type and
the digest content containing the intended digest type.
Martin Hoffmann contributed the idea of using the DS record of an already
signed zone also as a dry-run DS in order to facilitate testing key rollovers.

{backmatter}


# Implementation Status

**Note to the RFC Editor**: please remove this entire section before publication.

In the following implementation status descriptions, "dry-run DNSSEC" refers
to dry-run DNSSEC as described in this document.

* TODO


# Change History (to be removed before final publication)

* draft-yorgos-dnsop-dry-run-dnssec-00

> Initial public draft.
