# --dry-run DNSSEC

## Feedback from IETF 113

### This is another straw on the camel's back

- Ralf Weber and many others

Not all resolvers have to support/implement it. Most important is that
provisioning at the registry and signalling of Dry-run is supported. If needed
we can say it is OPTIONAL for resolvers in the draft. We intend to implement it
ourselves in Unbound and have it enabled by default when error reporting is
enabled. We know from experience with trust-anchor signalling and sentinel
record that with only a small, up to date  resolver population, the signalling
is already quite substantial.

There are different kind of straws and this one is one that has the good cause
of enabling operators to deploy DNSSEC with confidence.

### Why not have a duplicate parallel test deployment?

- Benjamin Schwartz

You don't get your actual user population to dry-run your DNSSEC deployment.

### Why not sell DNSSEC domains cheaper?

- Ralf Weber

Yes please! But, there are still domain-owners that cannot or do not want to
rely on third party DNS operators that will do the DNSSEC for them.

### Registry supports only fixed sized hashes per hash algorithm

- Feedback from Gavin from CentralNic.

- We could also have a Dry-run hash algorithm per DS algorithm.

  - disadvantage burn hash algorithms twice as fast

- Registries could also just change this rule for Dry-run.

### Hash is created from DNSKEY (or CDNSKEY)

- Feedback from Gavin Brown from CentralNIC.

- DNSKEYs do have space for flags which are ignored. There was a suggestion to
  use the flags in the DNSKEY to signal Dry-run, but we do not like it, because
  it makes the move to actual DNSSEC impossible without also changing the DNSKEY
  RRset.

### Idea: Have a general purpose DS Digest Type for signaling

- From Ben Schwartz

- To avoid polluting the digest type space with all the different ideas.

- Sure, it will be another draft dependency then. Personally we'd prefer Petr's
  idea (see below).

### Idea from Petr: Normalize the different DS hacks

- There are now several drafts on hold because they want to "misuse" DS for
  signalling. Petr's proposal: Why not have a range of RR types for which the
  parent is authoritative (like DS, and what NS should have been).

  This could work for Dry-run, we could have a DDS RR type which would have the
  same rdata as DS, but then signals Dry-run.

  We like it, but it creates another dependency for all these drafts (including
  ours) to progress.


### Would this be possible to test root DNSKEY (algorithm) rollover

- From Shane Kerr

It would be possible with Dry-run DS Digest Type in the <DigestType> element in
http://data.iana.org/root-anchors/root-anchors.xml or a different way of
indicating in the xml file.

---------------------------------

## Goal:
* --dry-run zones allow testing DNSSEC deployment before “actually” deploying
  and potentially breaking DNS.
* Validation errors for the --dry-run zone will be reported upstream with EDER
  and bogus answers will be treated as insecure (read more on --wet-run client).
* This allows deploying DNSSEC without SERVFAIL’ing for bogus answers. Gathered
  reports can help pinpoint faults in DNSSEC. When operator feels ready he can
  press the deploy button (publish the real DS record).

## Notes:
* DS --dry-run hack with extra digest type (@Roy suggested to put the actual
  digest type as first bits on the RDATA; followed by the actual value).
* Resolvers not understanding the DS digest type treat it as insecure by default.
* Everything under DS --dry-run is treated as secure, and insecure instead of
  bogus. Security consideration for the latter as it allows hijacks.
  (The option to always be insecure is not fully out of the question yet.)
  (Maybe it is, returning secure when possible is fine; stubs that don't
  validate don't care, stubs/clients that check the AD bit have more
  information to work with. This is still in the spirit of this proposal;
  testing DNSSEC but don't break DNS.)
* Main function is to report (EDNS upstream or client) DNSSEC errors. Should
  not be used instead of proper DNSSEC because it is not secure.
  Especially for dump clients(@Willem).
* CDS would work as expected. CDNSKEY cannot work by itself; it needs to be
  accompanied by a CDS to signal the --dry-run part (needs support by parents
  that do not accept DS records).
* --dry-run and real DS coexistence:

  why?
  * intentionally to test different DNSSEC options (eg., rolling to stronger
    algorithm key);
  * going from --dry-run to DNSSEC;
  * unintentionally because weird caches?;
  (question: can you have multiple DS for the same key?
             yes as long as the digest type changes)

  what?
  * If real DS is picked by validator, carry on.
  * If --dry-run is picked,
    * If everything OK, secure
    * If something not OK, should go back to real DS or insecure? (read more on
      --wet-run client)
      * if going back to real DS, something needs to be cached for the --dry-run
        so that we don’t generate EDER always. (caching the now secure/bogus
        answer from the real DS should solve this)
    * If something not OK and --wet-run client, bogus right there?

* real DS on child zone, --dry-run on parent zone:
  * child is secure/bogus as long as trust chain is valid
  * child may go insecure if trust chain becomes insecure. Parents should not
    --dry-run if children expect to be properly signed.

## Optional: (@Willem)
* --wet-run client could opt-in (new EDE option?) to treat DS --dry-run as
  “real” DS. This would mean secure/bogus answers to actually test client
  behavior if something is broken. This will make validators to prepare two
  answers (insecure and bogus) for potential normal and --wet-run clients.

## Questions:
* Should islands work (a subdomain of an unsigned zone)? This may generate more
  DS queries and may not work with all implementations if they know they are
  already traversing an insecure zone and thus ignoring DNSSEC logic. This
  could be desirable if you don’t want to fully commit to DNSSEC and just sign
  a subzone but with this proposal you can just --dry-run your whole
  tree, worst thing same answers as before with extra effort on the resolver
  side.
  Current reply: no
