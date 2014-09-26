require 'spec_helper'
require 'puppet'

provider_class = Puppet::Type.type(:conf_setting).provider(:ruby)
describe provider_class do
  include PuppetlabsSpec::Files

  let(:tmpfile) { tmpfilename("ini_setting_test.conf") }
  let(:emptyfile) { tmpfilename("ini_setting_test_empty.conf") }

  let(:common_params) { {
      :title    => 'ini_setting_ensure_present_test',
      :path     => tmpfile,
  } }

  def validate_file(expected_content,tmpfile = tmpfile)
    tmpcontent = File.read(tmpfile)
    File.read(tmpfile).should == expected_content
  end


  before :each do
    File.open(tmpfile, 'w') do |fh|
      fh.write(orig_content)
    end
    File.open(emptyfile, 'w') do |fh|
      fh.write("")
    end
  end

#   context 'when calling instances' do
#
#     let :orig_content do
#       ''
#     end
#
#     # it 'should fail when file path is not set' do
#     #   expect {
#     #     provider_class.instances
#     #   }.to raise_error(Puppet::Error, 'Ini_settings only support collecting instances when a file path is hard coded')
#     # end
#
#     context 'when file path is set by a child class' do
#       # it 'should return [] when file is empty' do
#       #   child_one = Class.new(provider_class) do
#       #     def self.file_path
#       #       emptyfile
#       #     end
#       #   end
#       #   child_one.stubs(:file_path).returns(emptyfile)
#       #   child_one.instances.should == []
#       # end
#       # it 'should override the provider instances file_path' do
#       #   child_two = Class.new(provider_class) do
#       #     def self.file_path
#       #       '/some/file/path'
#       #     end
#       #   end
#       #   resource = Puppet::Type::Ini_setting.new(common_params)
#       #   provider = child_two.new(resource)
#       #   provider.file_path.should == '/some/file/path'
#       # end
#       context 'when file has contents' do
#         let(:orig_content) {
#           <<-EOS
# # This is a comment
# [section1]
# ; This is also a comment
# foo=foovalue
#
# bar = barvalue
# master = true
# [section2]
#
# foo= foovalue2
# baz=bazvalue
# url = http://192.168.1.1:8080
# [section:sub]
# subby=bar
#     #another comment
#  ; yet another comment
#           EOS
#         }
#
#         # it 'should be able to parse the results' do
#         #   child_three = Class.new(provider_class) do
#         #     def self.file_path
#         #       '/some/file/path'
#         #     end
#         #   end
#         #   child_three.stubs(:file_path).returns(tmpfile)
#         #   child_three.instances.size == 7
#         #   expected_array = [
#         #     {:name => 'section1/foo', :value => 'foovalue' },
#         #     {:name => 'section1/bar', :value => 'barvalue' },
#         #     {:name => 'section1/master', :value => 'true' },
#         #     {:name => 'section2/foo', :value => 'foovalue2' },
#         #     {:name => 'section2/baz', :value => 'bazvalue' },
#         #     {:name => 'section2/url', :value => 'http://192.168.1.1:8080' },
#         #     {:name => 'section:sub/subby', :value => 'bar' }
#         #   ]
#         #   real_array = []
#         #   ensure_array = []
#         #   child_three.instances.each do |x|
#         #     prop_hash    = x.instance_variable_get(:@property_hash)
#         #     ensure_value = prop_hash.delete(:ensure)
#         #     ensure_array.push(ensure_value)
#         #     real_array.push(prop_hash)
#         #   end
#         #   ensure_array.uniq.should == [:present]
#         #   ((real_array - expected_array) && (expected_array - real_array)).should == []
#         #
#         # end
#
#       end
#
#     end
#
#   end

  context "when ensuring that a setting is present" do
    let(:orig_content) {
      <<-EOS
# This is a comment
test_key_1: {
// This is also a comment
  foo: foovalue

  bar: barvalue
  master: true
}

test_key_2: {

  foo: foovalue2
  baz: bazvalue
  url: "http://192.168.1.1:8080"
}

"test_key:3": {
  foo: bar
}
    #another comment
// yet another comment
foo: bar
      EOS
    }

    it "should add a missing setting to the correct map" do
      resource = Puppet::Type::Conf_setting.new(common_params.merge(
          :setting => 'test_key_1.yahoo', :value => 'yippee'))
      provider = described_class.new(resource)
      provider.exists?.should be false
      provider.create
      validate_file(<<-EOS
# This is a comment
"test_key_1" {
    # This is also a comment
    foo=foovalue
    bar=barvalue
    master=true
    yahoo=yippee
}
"test_key_2" {
    foo=foovalue2
    baz=bazvalue
    url="http://192.168.1.1:8080"
}
"test_key:3" {
    foo=bar
}
# another comment
# yet another comment
foo=bar
      EOS
)
    end

#     it "should add a missing setting to the correct section with colon" do
#       resource = Puppet::Type::Conf_setting.new(common_params.merge(
#                                                    :setting => 'test_key:3.yahoo', :value => 'yippee'))
#       provider = described_class.new(resource)
#       provider.exists?.should be false
#       provider.create
#       validate_file(<<-EOS
# # This is a comment
# "test_key_1" {
#     # This is also a comment
#     foo=foovalue
#     bar=barvalue
#     master=true
# }
# "test_key_2" {
#     foo=foovalue2
#     baz=bazvalue
#     url="http://192.168.1.1:8080"
# }
# "test_key:3" {
#     foo=bar
#     yahoo=yippee
# }
# # another comment
# # yet another comment
# foo=bar
# yahoo=yippee
#       EOS
#       )
#     end

    it "should modify an existing setting with a different value" do
      resource = Puppet::Type::Conf_setting.new(common_params.merge(
           :setting => 'test_key_2.baz', :value => 'bazvalue2'))
      provider = described_class.new(resource)
      provider.exists?.should be true
      provider.value=('bazvalue2')
      validate_file(<<-EOS
# This is a comment
"test_key_1" {
    # This is also a comment
    foo=foovalue
    bar=barvalue
    master=true
}
"test_key_2" {
    foo=foovalue2
    baz=bazvalue2
    url="http://192.168.1.1:8080"
}
"test_key:3" {
    foo=bar
}
# another comment
# yet another comment
foo=bar
      EOS
      )
    end

#     it "should modify an existing setting with a different value - with colon in section" do
#       resource = Puppet::Type::Ini_setting.new(common_params.merge(
#            :section => 'section:sub', :setting => 'subby', :value => 'foo'))
#       provider = described_class.new(resource)
#       provider.exists?.should be true
#       provider.value.should == 'bar'
#       provider.value=('foo')
#       validate_file(<<-EOS
# # This is a comment
# [section1]
# ; This is also a comment
# foo=foovalue
#
# bar = barvalue
# master = true
# [section2]
#
# foo= foovalue2
# baz=bazvalue
# url = http://192.168.1.1:8080
# [section:sub]
# subby=foo
#     #another comment
#  ; yet another comment
#       EOS
#       )
#     end

    it "should be able to handle settings with non alphanumbering settings " do
      resource = Puppet::Type::Conf_setting.new(common_params.merge(
           :setting => 'test_key_2.url', :value => 'http://192.168.0.1:8080'))
      provider = described_class.new(resource)
      provider.exists?.should be true
      provider.value.should == 'http://192.168.1.1:8080'
      provider.value=('http://192.168.0.1:8080')

      validate_file(<<-EOS
# This is a comment
"test_key_1" {
    # This is also a comment
    foo=foovalue
    bar=barvalue
    master=true
}
"test_key_2" {
    foo=foovalue2
    baz=bazvalue
    url="http://192.168.0.1:8080"
}
"test_key:3" {
    foo=bar
}
# another comment
# yet another comment
foo=bar
      EOS
      )
    end

    it "should recognize an existing setting with the specified value" do
      resource = Puppet::Type::Conf_setting.new(common_params.merge(
           :setting => 'test_key_2.baz', :value => 'bazvalue'))
      provider = described_class.new(resource)
      provider.exists?.should be true
    end

    it "should add a new map if the path contains a non-existent map" do
      resource = Puppet::Type::Conf_setting.new(common_params.merge(
          :setting => 'test_key_4.huzzah', :value => 'shazaam'))
      provider = described_class.new(resource)
      provider.exists?.should be false
      provider.create
      validate_file(<<-EOS
# This is a comment
"test_key_1" {
    # This is also a comment
    foo=foovalue
    bar=barvalue
    master=true
}
"test_key_2" {
    foo=foovalue2
    baz=bazvalue
    url="http://192.168.1.1:8080"
}
"test_key:3" {
    foo=bar
}
# another comment
# yet another comment
foo=bar
"test_key_4" {
    huzzah=shazaam
}
      EOS
      )
    end
#
#     it "should add a new section if the section does not exist - with colon" do
#       resource = Puppet::Type::Ini_setting.new(common_params.merge(
#           :section => "section:subsection", :setting => 'huzzah', :value => 'shazaam'))
#       provider = described_class.new(resource)
#       provider.exists?.should be false
#       provider.create
#       validate_file(<<-EOS
# # This is a comment
# [section1]
# ; This is also a comment
# foo=foovalue
#
# bar = barvalue
# master = true
# [section2]
#
# foo= foovalue2
# baz=bazvalue
# url = http://192.168.1.1:8080
# [section:sub]
# subby=bar
#     #another comment
#  ; yet another comment
#
# [section:subsection]
# huzzah = shazaam
#       EOS
#       )
#     end

    it "should add a new map if no maps exists" do
      resource = Puppet::Type::Conf_setting.new(common_params.merge(
          :setting => 'test_key_1.setting1', :value => 'hellowworld', :path => emptyfile))
      provider = described_class.new(resource)
      provider.exists?.should be false
      provider.create
      validate_file(
"\"test_key_1\" {
    setting1=hellowworld
}
", emptyfile)
    end

#     it "should add a new section with colon if no sections exists" do
#       resource = Puppet::Type::Ini_setting.new(common_params.merge(
#           :section => "section:subsection", :setting => 'setting1', :value => 'hellowworld', :path => emptyfile))
#       provider = described_class.new(resource)
#       provider.exists?.should be false
#       provider.create
#       validate_file("
# [section:subsection]
# setting1 = hellowworld
# ", emptyfile)
#     end
#
    it "should be able to handle variables of any type" do
      resource = Puppet::Type::Conf_setting.new(common_params.merge(
          :setting => 'test_key_1.master', :value => true))
      provider = described_class.new(resource)
      provider.exists?.should be true
      provider.value.should eql(true)
    end

  end

  context "when dealing with settings in the top level" do
    let(:orig_content) {
      <<-EOS
# This is a comment
foo=blah
"test_key_1" {
    # yet another comment
    foo="http://192.168.1.1:8080"
}
      EOS
    }


    it "should add a missing setting if it doesn't exist" do
      resource = Puppet::Type::Conf_setting.new(common_params.merge(
          :setting => 'bar', :value => 'yippee'))
      provider = described_class.new(resource)
      provider.exists?.should be false
      provider.create
      validate_file(<<-EOS
# This is a comment
foo=blah
"test_key_1" {
    # yet another comment
    foo="http://192.168.1.1:8080"
}
bar=yippee
      EOS
      )
    end

    # TODO: Investigate removal of comment
    it "should modify an existing setting with a different value" do
      resource = Puppet::Type::Conf_setting.new(common_params.merge(
           :setting => 'foo', :value => 'yippee'))
      provider = described_class.new(resource)
      provider.exists?.should be true
      provider.value.should == 'blah'
      provider.value=('yippee')
      validate_file(<<-EOS
foo=yippee
"test_key_1" {
    # yet another comment
    foo="http://192.168.1.1:8080"
}
      EOS
      )
    end

    it "should recognize an existing setting with the specified value" do
      resource = Puppet::Type::Conf_setting.new(common_params.merge(
           :section => '', :setting => 'foo', :value => 'blah'))
      provider = described_class.new(resource)
      provider.exists?.should be true
    end
  end

   context "when the first line of the file is a section" do
    let(:orig_content) {
      <<-EOS
"test_key_2" {
    foo="http://192.168.1.1:8080"
}
      EOS
    }

    it "should be able to add a setting to the top-level map" do
      resource = Puppet::Type::Conf_setting.new(common_params.merge(
           :setting => 'foo', :value => 'yippee'))
      provider = described_class.new(resource)
      provider.exists?.should be false
      provider.create
      validate_file(<<-EOS
"test_key_2" {
    foo="http://192.168.1.1:8080"
}
foo=yippee
      EOS
      )
    end
  end

  context "when overriding the separator" do
    let(:orig_content) {
      <<-EOS
[section2]
foo=bar
      EOS
    }

#     it "should fail if the separator doesn't include an equals sign" do
#       expect {
#         Puppet::Type::Ini_setting.new(common_params.merge(
#                                          :section           => 'section2',
#                                          :setting           => 'foo',
#                                          :value             => 'yippee',
#                                          :key_val_separator => '+'))
#       }.to raise_error Puppet::Error, /must contain exactly one/
#     end
#
#     it "should fail if the separator includes more than one equals sign" do
#       expect {
#         Puppet::Type::Ini_setting.new(common_params.merge(
#                                          :section           => 'section2',
#                                          :setting           => 'foo',
#                                          :value             => 'yippee',
#                                          :key_val_separator => ' = foo = '))
#       }.to raise_error Puppet::Error, /must contain exactly one/
#     end
#
#     it "should modify an existing setting" do
#       resource = Puppet::Type::Ini_setting.new(common_params.merge(
#                                                    :section           => 'section2',
#                                                    :setting           => 'foo',
#                                                    :value             => 'yippee',
#                                                    :key_val_separator => '='))
#       provider = described_class.new(resource)
#       provider.exists?.should be true
#       provider.value.should == 'bar'
#       provider.value=('yippee')
#       validate_file(<<-EOS
# [section2]
# foo=yippee
#       EOS
#       )
#     end
#
#     it "should add a new setting" do
#       resource = Puppet::Type::Ini_setting.new(common_params.merge(
#                                                    :section           => 'section2',
#                                                    :setting           => 'bar',
#                                                    :value             => 'baz',
#                                                    :key_val_separator => '='))
#       provider = described_class.new(resource)
#       provider.exists?.should be false
#       provider.create
#       validate_file(<<-EOS
# [section2]
# foo=bar
# bar=baz
#       EOS
#       )
#     end

  end

  context "when ensuring that a setting is absent" do
    let(:orig_content) {
      <<-EOS
[section1]
; This is also a comment
foo=foovalue

bar = barvalue
master = true
[section2]

foo= foovalue2
baz=bazvalue
url = http://192.168.1.1:8080
[section:sub]
subby=bar
    #another comment
 ; yet another comment
EOS
    }

#     it "should remove a setting that exists" do
#       resource = Puppet::Type::Ini_setting.new(common_params.merge(
#       :section => 'section1', :setting => 'foo', :ensure => 'absent'))
#       provider = described_class.new(resource)
#       provider.exists?.should be true
#       provider.destroy
#       validate_file(<<-EOS
# [section1]
# ; This is also a comment
#
# bar = barvalue
# master = true
# [section2]
#
# foo= foovalue2
# baz=bazvalue
# url = http://192.168.1.1:8080
# [section:sub]
# subby=bar
#     #another comment
#  ; yet another comment
# EOS
#     )
#     end
#
#     it "should do nothing for a setting that does not exist" do
#       resource = Puppet::Type::Ini_setting.new(common_params.merge(
#                                                    :section => 'section:sub', :setting => 'foo', :ensure => 'absent'))
#       provider = described_class.new(resource)
#       provider.exists?.should be false
#       provider.destroy
#       validate_file(<<-EOS
# [section1]
# ; This is also a comment
# foo=foovalue
#
# bar = barvalue
# master = true
# [section2]
#
# foo= foovalue2
# baz=bazvalue
# url = http://192.168.1.1:8080
# [section:sub]
# subby=bar
#     #another comment
#  ; yet another comment
#       EOS
#       )
#     end
  end


  context "when dealing with indentation in sections" do
    let(:orig_content) {
      <<-EOS
# This is a comment
     [section1]
     ; This is also a comment
     foo=foovalue

     bar = barvalue
     master = true

[section2]
  foo= foovalue2
  baz=bazvalue
  url = http://192.168.1.1:8080
[section:sub]
 subby=bar
    #another comment
  fleezy = flam
 ; yet another comment
      EOS
    }

#     it "should add a missing setting at the correct indentation when the header is aligned" do
#       resource = Puppet::Type::Ini_setting.new(common_params.merge(
#                     :section => 'section1', :setting => 'yahoo', :value => 'yippee'))
#       provider = described_class.new(resource)
#       provider.exists?.should be false
#       provider.create
#       validate_file(<<-EOS
# # This is a comment
#      [section1]
#      ; This is also a comment
#      foo=foovalue
#
#      bar = barvalue
#      master = true
#      yahoo = yippee
#
# [section2]
#   foo= foovalue2
#   baz=bazvalue
#   url = http://192.168.1.1:8080
# [section:sub]
#  subby=bar
#     #another comment
#   fleezy = flam
#  ; yet another comment
#       EOS
#       )
#     end
#
#     it "should update an existing setting at the correct indentation when the header is aligned" do
#       resource = Puppet::Type::Ini_setting.new(
#           common_params.merge(:section => 'section1', :setting => 'bar', :value => 'barvalue2'))
#       provider = described_class.new(resource)
#       provider.exists?.should be true
#       provider.create
#       validate_file(<<-EOS
# # This is a comment
#      [section1]
#      ; This is also a comment
#      foo=foovalue
#
#      bar = barvalue2
#      master = true
#
# [section2]
#   foo= foovalue2
#   baz=bazvalue
#   url = http://192.168.1.1:8080
# [section:sub]
#  subby=bar
#     #another comment
#   fleezy = flam
#  ; yet another comment
#       EOS
#       )
#     end
#
#     it "should add a missing setting at the correct indentation when the header is not aligned" do
#       resource = Puppet::Type::Ini_setting.new(common_params.merge(
#                                                    :section => 'section2', :setting => 'yahoo', :value => 'yippee'))
#       provider = described_class.new(resource)
#       provider.exists?.should be false
#       provider.create
#       validate_file(<<-EOS
# # This is a comment
#      [section1]
#      ; This is also a comment
#      foo=foovalue
#
#      bar = barvalue
#      master = true
#
# [section2]
#   foo= foovalue2
#   baz=bazvalue
#   url = http://192.168.1.1:8080
#   yahoo = yippee
# [section:sub]
#  subby=bar
#     #another comment
#   fleezy = flam
#  ; yet another comment
#       EOS
#       )
#     end
#
#     it "should update an existing setting at the correct indentation when the header is not aligned" do
#       resource = Puppet::Type::Ini_setting.new(
#           common_params.merge(:section => 'section2', :setting => 'baz', :value => 'bazvalue2'))
#       provider = described_class.new(resource)
#       provider.exists?.should be true
#       provider.create
#       validate_file(<<-EOS
# # This is a comment
#      [section1]
#      ; This is also a comment
#      foo=foovalue
#
#      bar = barvalue
#      master = true
#
# [section2]
#   foo= foovalue2
#   baz=bazvalue2
#   url = http://192.168.1.1:8080
# [section:sub]
#  subby=bar
#     #another comment
#   fleezy = flam
#  ; yet another comment
#       EOS
#       )
#     end
#
#     it "should add a missing setting at the min indentation when the section is not aligned" do
#       resource = Puppet::Type::Ini_setting.new(
#           common_params.merge(:section => 'section:sub', :setting => 'yahoo', :value => 'yippee'))
#       provider = described_class.new(resource)
#       provider.exists?.should be false
#       provider.create
#       validate_file(<<-EOS
# # This is a comment
#      [section1]
#      ; This is also a comment
#      foo=foovalue
#
#      bar = barvalue
#      master = true
#
# [section2]
#   foo= foovalue2
#   baz=bazvalue
#   url = http://192.168.1.1:8080
# [section:sub]
#  subby=bar
#     #another comment
#   fleezy = flam
#  ; yet another comment
#  yahoo = yippee
#       EOS
#       )
#     end
#
#     it "should update an existing setting at the previous indentation when the section is not aligned" do
#       resource = Puppet::Type::Ini_setting.new(
#           common_params.merge(:section => 'section:sub', :setting => 'fleezy', :value => 'flam2'))
#       provider = described_class.new(resource)
#       provider.exists?.should be true
#       provider.create
#       validate_file(<<-EOS
# # This is a comment
#      [section1]
#      ; This is also a comment
#      foo=foovalue
#
#      bar = barvalue
#      master = true
#
# [section2]
#   foo= foovalue2
#   baz=bazvalue
#   url = http://192.168.1.1:8080
# [section:sub]
#  subby=bar
#     #another comment
#   fleezy = flam2
#  ; yet another comment
#       EOS
#       )
#     end

  end


  context "when dealing settings that have a commented version present" do
    let(:orig_content) {
      <<-EOS
     [section1]
     # foo=foovalue
     bar=barvalue
     foo = foovalue2

[section2]
# foo = foovalue
;bar=barvalue
blah = blah
#baz=
      EOS
    }

#     it "should add a new setting below a commented version of that setting" do
#       resource = Puppet::Type::Ini_setting.new(
#           common_params.merge(:section => 'section2', :setting => 'foo', :value => 'foo3'))
#       provider = described_class.new(resource)
#       provider.exists?.should be false
#       provider.create
#       validate_file(<<-EOS
#      [section1]
#      # foo=foovalue
#      bar=barvalue
#      foo = foovalue2
#
# [section2]
# # foo = foovalue
# foo = foo3
# ;bar=barvalue
# blah = blah
# #baz=
#       EOS
#       )
#     end
#
#     it "should update an existing setting in place, even if there is a commented version of that setting" do
#       resource = Puppet::Type::Ini_setting.new(
#           common_params.merge(:section => 'section1', :setting => 'foo', :value => 'foo3'))
#       provider = described_class.new(resource)
#       provider.exists?.should be true
#       provider.create
#       validate_file(<<-EOS
#      [section1]
#      # foo=foovalue
#      bar=barvalue
#      foo = foo3
#
# [section2]
# # foo = foovalue
# ;bar=barvalue
# blah = blah
# #baz=
#       EOS
#       )
#     end
#
#     it "should add a new setting below a commented version of that setting, respecting semicolons as comments" do
#       resource = Puppet::Type::Ini_setting.new(
#           common_params.merge(:section => 'section2', :setting => 'bar', :value => 'bar3'))
#       provider = described_class.new(resource)
#       provider.exists?.should be false
#       provider.create
#       validate_file(<<-EOS
#      [section1]
#      # foo=foovalue
#      bar=barvalue
#      foo = foovalue2
#
# [section2]
# # foo = foovalue
# ;bar=barvalue
# bar=bar3
# blah = blah
# #baz=
#       EOS
#       )
#     end
#
#     it "should add a new setting below an empty commented version of that setting" do
#       resource = Puppet::Type::Ini_setting.new(
#           common_params.merge(:section => 'section2', :setting => 'baz', :value => 'bazvalue'))
#       provider = described_class.new(resource)
#       provider.exists?.should be false
#       provider.create
#       validate_file(<<-EOS
#      [section1]
#      # foo=foovalue
#      bar=barvalue
#      foo = foovalue2
#
# [section2]
# # foo = foovalue
# ;bar=barvalue
# blah = blah
# #baz=
# baz=bazvalue
#       EOS
#       )
#     end

    context 'when a section only contains comments' do
     let(:orig_content) {
      <<-EOS
[section1]
# foo=foovalue
# bar=bar2
EOS
    }
#       it 'should be able to add a new setting when a section contains only comments' do
#         resource = Puppet::Type::Ini_setting.new(
#           common_params.merge(:section => 'section1', :setting => 'foo', :value => 'foovalue2')
#         )
#         provider = described_class.new(resource)
#         provider.exists?.should be false
#         provider.create
#         validate_file(<<-EOS
# [section1]
# # foo=foovalue
# foo=foovalue2
# # bar=bar2
#         EOS
#         )
#       end
#       it 'should be able to add a new setting when it matches a commented out line other than the first one' do
#         resource = Puppet::Type::Ini_setting.new(
#           common_params.merge(:section => 'section1', :setting => 'bar', :value => 'barvalue2')
#         )
#         provider = described_class.new(resource)
#         provider.exists?.should be false
#         provider.create
#         validate_file(<<-EOS
# [section1]
# # foo=foovalue
# # bar=bar2
# bar=barvalue2
#         EOS
#         )
#       end
    end

    context "when sections have spaces and dashes" do
      let(:orig_content) {
        <<-EOS
# This is a comment
[section - one]
; This is also a comment
foo=foovalue

bar = barvalue
master = true
[section - two]

foo= foovalue2
baz=bazvalue
url = http://192.168.1.1:8080
[section:sub]
subby=bar
    #another comment
 ; yet another comment
        EOS
      }
#
#       it "should add a missing setting to the correct section" do
#         resource = Puppet::Type::Ini_setting.new(common_params.merge(
#             :section => 'section - two', :setting => 'yahoo', :value => 'yippee'))
#         provider = described_class.new(resource)
#         provider.exists?.should be false
#         provider.create
#         validate_file(<<-EOS
# # This is a comment
# [section - one]
# ; This is also a comment
# foo=foovalue
#
# bar = barvalue
# master = true
# [section - two]
#
# foo= foovalue2
# baz=bazvalue
# url = http://192.168.1.1:8080
# yahoo = yippee
# [section:sub]
# subby=bar
#     #another comment
#  ; yet another comment
#         EOS
#   )
#       end

    end

  end

  context "when sections have spaces and quotations" do
    let(:orig_content) do
      <<-EOS
[branch "master"]
        remote = origin
        merge = refs/heads/master

[alias]
to-deploy = log --merges --grep='pull request' --format='%s (%cN)' origin/production..origin/master
[branch "production"]
        remote = origin
        merge = refs/heads/production
      EOS
    end

#     it "should add a missing setting to the correct section" do
#       resource = Puppet::Type::Ini_setting.new(common_params.merge(
#         :section => 'alias',
#         :setting => 'foo',
#         :value => 'bar'
#       ))
#       provider = described_class.new(resource)
#       provider.exists?.should be false
#       provider.create
#       validate_file(<<-EOS
# [branch "master"]
#         remote = origin
#         merge = refs/heads/master
#
# [alias]
# to-deploy = log --merges --grep='pull request' --format='%s (%cN)' origin/production..origin/master
# foo = bar
# [branch "production"]
#         remote = origin
#         merge = refs/heads/production
#                     EOS
#                    )
#     end

  end

end
