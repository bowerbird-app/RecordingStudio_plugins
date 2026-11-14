# Recording Studio kit pin update

Copied addons now start on the Recording Studio 6.14 host-kit floor.

- Gemspec: `add_dependency "recording_studio", ">= 6.14.0"`
- Dummy GitHub tags: Recording Studio `v6.14.0`, Accessible `v0.32.0`, Root Switchable `v0.15.0`, FlatPack `v0.1.357`, Dashboard `v0.4.1`
- Authenticated dummy layout: `recording_studio_layout` plus FlatPack CSS/JS
- Hooks and BaseService come from core; do not copy them into a new addon
- Recordable declarations remain required
