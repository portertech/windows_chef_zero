## A Chef Zero provisioner for Windows

This is a temporarily solution to a problem, getting Test-Kitchen to work on Windows.

## Usage

Use https://github.com/joefitzgerald/packer-windows to build a box, `windows_2012_r2`.

Gemfile

```
gem "windows_chef_zero"
```

.kitchen.yml

```
platforms:
  name: windows_2012_r2
  driver:
    box: windows_2012_r2
    customize:
      memory: 2048
  provisioner:
    name: windows_chef_zero
```

## Contributing

1. Fork it ( https://github.com/portertech/windows_chef_zero/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
