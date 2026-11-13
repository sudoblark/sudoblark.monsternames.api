"""Composable handler mixins.

Small, single-purpose mixins a Lambda handler inherits to gain one capability,
such as a lazily built repository. They sit at the handler's edge, above the
repositories; they are not repositories themselves.
"""
