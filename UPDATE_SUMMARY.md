# Recording Studio kit pin update

Copied addons now start on the Recording Studio 6.1 host-kit floor.

- Gemspec: `add_dependency "recording_studio", ">= 6.1.0"`
- Dummy GitHub tags: Recording Studio `v6.1.0`, Accessible `v0.22.0`, Root Switchable `v0.8.0`, FlatPack `v0.1.329`
- Authenticated dummy layout: `recording_studio_layout` plus FlatPack CSS/JS
- Hooks and BaseService come from core; do not copy them into a new addon
- Recordable declarations remain required
