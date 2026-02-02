# Modified gitflow

This is a 'develop' is default branch repo.
All PullRequests go to develop.
All feature branches come from develop.

All releases are done from master.
All tags are on master, with the exception of 'alpha' or 'beta' tags.
Alpha or Beta tags are on either develop, or a release branch from develop.

Bugs, workflows, and stubs are updated on master.
Then merged to develop.

Merging up towards master involve 'commit merges' (merge --no-ff).
