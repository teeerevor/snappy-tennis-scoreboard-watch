# Companion App is included in the existing purchase

The Watch App is a paid, up-front purchase, and some users have already bought it. We ship the iPhone/iPad Companion App as part of the same App Store listing (universal purchase), so existing buyers get it at no extra cost and new buyers pay one price for both. We rejected an in-app purchase for the extra features (more revenue, but adds StoreKit and grandfathering logic) and a separate paid listing (customers would pay twice and get confused).

## Consequences

- There is deliberately no StoreKit code. If paid extras are added later, use an in-app purchase that existing buyers get free, based on their original purchase date (`AppTransaction.originalAppVersion`).
- The Watch App must keep working fully on its own: the Companion App only adds features.
