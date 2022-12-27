require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Scancode do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ scancode }).should.be.instance_of Command::Scancode
      end
    end
  end
end

