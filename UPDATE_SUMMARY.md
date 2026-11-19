# Recording Studio kit pin update

Copied addons now start on the Recording Studio 7 host-kit floor.

- Gemspec: `add_dependency "recording_studio", ">= 7.0", "< 8.0"`
- Dummy GitHub tags: Recording Studio `v7.8.0`, Accessible `v0.58.0`, Root Switchable `v0.17.0`, FlatPack `v0.2.0`, Dashboard `v0.6.0`
- Authenticated dummy layout: `recording_studio_layout` plus FlatPack CSS/JS
- Hooks and BaseService come from core; do not copy them into a new addon
- Recordable declarations remain required
