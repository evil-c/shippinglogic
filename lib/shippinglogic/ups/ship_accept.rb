require "base64"

module Shippinglogic
  class UPS
    class ShipAccept < Service
      def self.path
        "/ShipAccept"
      end
      
      class Details
        class Shipment; attr_accessor :tracking_number, :label; end
        
        attr_accessor :rate, :currency, :shipments
        
        def initialize(response)
          details = response[:shipment_results]
          
          charges       = details[:shipment_charges][:total_charges]
          self.rate     = BigDecimal.new(charges[:monetary_value])
          self.currency = charges[:currency_code]
          
          package_results = details[:package_results]
          
          packages = if package_results.is_a?(Array)
            [*package_results]
          else
            [package_results]
          end
          
          self.shipments = packages.collect do |package|
            shipment                  = Shipment.new
            shipment.tracking_number  = package[:tracking_number]
            shipment.label            = package[:label_image][:graphic_image]
            shipment
          end
        end
      end
      
      attribute :digest, :string
      
      private
        def target
          @target ||= Details.new(request(build_request))
        end
        
        def build_request
          b = builder
          build_authentication(b)
          b.instruct!
          
          b.ShipmentAcceptRequest do
            b.Request do
              b.RequestAction "ShipAccept"
            end
            
            b.ShipmentDigest digest
          end
        end
    end
  end
end