class ServiceResourceAttachment < ApplicationRecord
  include NewWithTypeStiMixin
  include ProviderObjectMixin
  include AsyncDeleteMixin
  include AvailabilityMixin
  include SupportsFeatureMixin
  include CustomActionsMixin

  belongs_to :ext_management_system, :foreign_key => :ems_id, :class_name => "ExtManagementSystem"
  belongs_to :storage_service, :foreign_key => :storage_service_id, :class_name => "StorageService"
  belongs_to :storage_resource, :foreign_key => :storage_resource_id, :class_name => "StorageResource"


  acts_as_miq_taggable


  def self.available
    #left_outer_joins(:attachments).where("disks.backing_id" => nil)
  end

  def self.class_by_ems(ext_management_system)
    # TODO(lsmola) taken from OrchesTration stacks, correct approach should be to have a factory on ExtManagementSystem
    # side, that would return correct class for each provider
    ext_management_system && ext_management_system.class::StorageSystem
  end


end
