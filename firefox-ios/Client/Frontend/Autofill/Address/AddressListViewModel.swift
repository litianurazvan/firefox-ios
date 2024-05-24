// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Shared
import Storage

// TODO: PHASE-2 FXIOS-7653
// AddressListViewModelDelegate: A protocol to notify delegates about address updates.
// protocol AddressListViewModelDelegate: AnyObject {
//     func didUpdateAddresses(_ addresses: [Address])
// }

// TODO: Refactor the Address extension for global usage (FXIOS-8337)
extension Address {
    var addressCityStateZipcode: String {
        return "\(addressLevel2), \(addressLevel1) \(postalCode)"
    }
}

// AddressListViewModel: A view model for managing addresses.
class AddressListViewModel: ObservableObject, FeatureFlaggable {
    // MARK: - Properties

    @Published var addresses: [Address] = []
    @Published var showSection = false
    @Published var destination: Destination?

    var saveAction: (() -> Void)?

    enum Destination: Swift.Identifiable {
        case add(Address)
        case edit(Address)

        var id: String {
            switch self {
            case .add(let value):
                return value.guid
            case .edit(let value):
                return value.guid
            }
        }
    }

    private let logger: Logger

    var isEditingFeatureEnabled: Bool { featureFlags.isFeatureEnabled(.addressAutofillEdit, checking: .buildOnly) }

    var addressSelectionCallback: ((UnencryptedAddressFields) -> Void)?

    let addressProvider: AddressProvider

    // MARK: - Initializer

    /// Initializes the AddressListViewModel.
    init(
        logger: Logger = DefaultLogger.shared,
        addressProvider: AddressProvider
    ) {
        self.logger = logger
        self.addressProvider = addressProvider
    }

    // MARK: - Fetch Addresses

    /// Fetches addresses from the associated profile's autofill.
    func fetchAddresses() {
        // Assuming profile is a class-level variable
        addressProvider.listAllAddresses { [weak self] storedAddresses, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let addresses = storedAddresses {
                    self.addresses = addresses
                    self.showSection = !addresses.isEmpty
                } else if let error = error {
                    self.logger.log("Error fetching addresses",
                                    level: .warning,
                                    category: .autofill,
                                    description: "Error fetching addresses: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Converts an Address object to UnencryptedAddressFields.
    /// - Parameter address: The address to be converted.
    /// - Returns: The UnencryptedAddressFields representation of the address.
    func fromAddress(_ address: Address) -> UnencryptedAddressFields {
        return UnencryptedAddressFields(addressLevel1: address.addressLevel1,
                                        organization: address.organization,
                                        country: address.country,
                                        addressLevel2: address.addressLevel2,
                                        addressLevel3: address.addressLevel3,
                                        email: address.email,
                                        streetAddress: address.streetAddress,
                                        name: address.name,
                                        postalCode: address.postalCode,
                                        tel: address.tel)
    }

    // MARK: - Handle Address Selection

    /// Handles the selection of an address.
    /// - Parameter address: The selected address.
    func handleAddressSelection(_ address: Address) {
        addressSelectionCallback?(fromAddress(address))
    }

    func addressTapped(_ address: Address) {
        destination = .edit(address)
    }

    func cancelEditButtonTap() {
        destination = nil
    }

    func cancelAddButtonTap() {
        destination = nil
    }

    func saveAddress(completion: (Address) -> Void) {
        saveAction?()
    }

    func addButtonTap() {
        destination = .add(Address(
            guid: "",
            name: "",
            organization: "",
            streetAddress: "",
            addressLevel3: "",
            addressLevel2: "",
            addressLevel1: "",
            postalCode: "",
            country: "",
            tel: "",
            email: "",
            timeCreated: 0,
            timeLastUsed: nil,
            timeLastModified: 0,
            timesUsed: 0
        ))
    }

    // MARK: - Inject JSON Data

    struct JSONDataError: Error {}

    func getInjectJSONDataInit() throws -> String {
        guard let destination = self.destination else {
            throw JSONDataError()
        }

        do {
            let address: Address =
            switch destination {
            case .add(let address):
                address
            case .edit(let address):
                address
            }

            let addressString = try jsonString(from: address)
            let l10sString = try jsonString(from: EditAddressLocalization.editAddressLocalizationIDs)

            let javascript = "init(\(addressString), \(l10sString));"
            return javascript
        } catch {
            logger.log("Failed to encode data",
                       level: .warning,
                       category: .autofill,
                       description: "Failed to encode data with error: \(error.localizedDescription)")
            throw error
        }
    }

    private func jsonString<T: Encodable>(from object: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.userInfo[.formatStyleKey] = FormatStyle.kebabCase
        let data = try encoder.encode(object)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(
                object,
                EncodingError.Context(codingPath: [], debugDescription: "Unable to convert data to String")
            )
        }
        return jsonString.replacingOccurrences(of: "\\", with: "\\\\")
    }
}
