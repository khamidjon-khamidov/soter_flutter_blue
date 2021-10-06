#include "include/soter_flutter_blue/soter_flutter_blue_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Storage.Streams.h>
#include <winrt/Windows.Devices.Radios.h>
#include <winrt/Windows.Devices.Bluetooth.h>
#include <winrt/Windows.Devices.Bluetooth.Advertisement.h>
#include <winrt/Windows.Devices.Bluetooth.GenericAttributeProfile.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/basic_message_channel.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/standard_message_codec.h>

#include <map>
#include <memory>
#include <sstream>
#include <sstream>
#include <algorithm>
#include <iomanip>
#include <chrono>
#include <thread>

#define GUID_FORMAT "%08x-%04hx-%04hx-%02hhx%02hhx-%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx"
#define GUID_ARG(guid) guid.Data1, guid.Data2, guid.Data3, guid.Data4[0], guid.Data4[1], guid.Data4[2], guid.Data4[3], guid.Data4[4], guid.Data4[5], guid.Data4[6], guid.Data4[7]

namespace {

using namespace winrt::Windows::Foundation;
using namespace winrt::Windows::Foundation::Collections;
using namespace winrt::Windows::Storage::Streams;
using namespace winrt::Windows::Devices::Radios;
using namespace winrt::Windows::Devices::Bluetooth;
using namespace winrt::Windows::Devices::Bluetooth::Advertisement;
using namespace winrt::Windows::Devices::Bluetooth::GenericAttributeProfile;
using namespace std::this_thread; // sleep_for, sleep_until
using namespace std::chrono;
using namespace winrt::Windows::System;

using flutter::EncodableValue;
using flutter::EncodableMap;
using flutter::EncodableList;

union uint16_t_union {
  uint16_t uint16;
  byte bytes[sizeof(uint16_t)];
};

std::vector<uint8_t> to_bytevc(IBuffer buffer) {
  auto reader = DataReader::FromBuffer(buffer);
  auto result = std::vector<uint8_t>(reader.UnconsumedBufferLength());
  reader.ReadBytes(result);
  return result;
}

IBuffer from_bytevc(std::vector<uint8_t> bytes) {
  auto writer = DataWriter();
  writer.WriteBytes(bytes);
  return writer.DetachBuffer();
}

std::string to_hexstring(std::vector<uint8_t> bytes) {
  auto ss = std::stringstream();
  for (auto b : bytes)
      ss << std::setw(2) << std::setfill('0') << std::hex << static_cast<int>(b);
  return ss.str();
}

std::string to_uuidstr(winrt::guid guid) {
  char chars[36 + 1];
  sprintf_s(chars, GUID_FORMAT, GUID_ARG(guid));
  return std::string{ chars };
}

struct BluetoothDeviceAgent {
  BluetoothLEDevice device;
  winrt::event_token connnectionStatusChangedToken;
  std::map<std::string, GattDeviceService> gattServices;
  std::map<std::string, GattCharacteristic> gattCharacteristics;
  std::map<std::string, winrt::event_token> valueChangedTokens;

  BluetoothDeviceAgent(BluetoothLEDevice device, winrt::event_token connnectionStatusChangedToken)
      : device(device),
        connnectionStatusChangedToken(connnectionStatusChangedToken) {}

  ~BluetoothDeviceAgent() {
    device = nullptr;
  }

  IAsyncOperation<GattDeviceService> GetServiceAsync(std::string service) {
    if (gattServices.count(service) == 0) {
      auto serviceResult = co_await device.GetGattServicesAsync();
      if (serviceResult.Status() != GattCommunicationStatus::Success)
        co_return nullptr;

      for (auto s : serviceResult.Services())
        if (to_uuidstr(s.Uuid()) == service)
          gattServices.insert(std::make_pair(service, s));
    }
    co_return gattServices.at(service);
  }

  IAsyncOperation<GattCharacteristic> GetCharacteristicAsync(std::string service, std::string characteristic) {
    if (gattCharacteristics.count(characteristic) == 0) {
      auto gattService = co_await GetServiceAsync(service);

      auto characteristicResult = co_await gattService.GetCharacteristicsAsync();
      if (characteristicResult.Status() != GattCommunicationStatus::Success)
        co_return nullptr;

      for (auto c : characteristicResult.Characteristics())
        if (to_uuidstr(c.Uuid()) == characteristic)
          gattCharacteristics.insert(std::make_pair(characteristic, c));
    }
    co_return gattCharacteristics.at(characteristic);
  }
};


class SoterFlutterBluePlugin : public flutter::Plugin, public flutter::StreamHandler<EncodableValue> {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  SoterFlutterBluePlugin();

  virtual ~SoterFlutterBluePlugin();

 private:
 winrt::fire_and_forget InitializeAsync();

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::unique_ptr<flutter::StreamHandlerError<>> OnListenInternal(
      const EncodableValue* arguments,
      std::unique_ptr<flutter::EventSink<>>&& events) override;

  std::unique_ptr<flutter::StreamHandlerError<>> OnCancelInternal(
      const EncodableValue* arguments) override;

  std::unique_ptr<flutter::BasicMessageChannel<EncodableValue>> message_connector_;

  Radio bluetoothRadio{ nullptr };

  BluetoothLEAdvertisementWatcher bluetoothLEWatcher =  { nullptr }; // BluetoothLEAdvertisementWatcher();
  winrt::event_token bluetoothLEWatcherReceivedToken;
  void BluetoothLEWatcher_Received(BluetoothLEAdvertisementWatcher sender, BluetoothLEAdvertisementReceivedEventArgs args);
  void OnAdvertisementStopped (BluetoothLEAdvertisementWatcher sender, BluetoothLEAdvertisementWatcherStoppedEventArgs  args);
  std::map<uint64_t, std::unique_ptr<BluetoothDeviceAgent>> connectedDevices{};

  winrt::fire_and_forget DiscoverServicesAsync(uint64_t bluetoothAddress, std::string deviceId);
  winrt::fire_and_forget ConnectAsync(uint64_t bluetoothAddress);
  void BluetoothLEDevice_ConnectionStatusChanged(BluetoothLEDevice sender, IInspectable args);
  void CleanConnection(uint64_t bluetoothAddress);
  void DisconnectAllDevices();

  winrt::fire_and_forget SetNotifiableAsync(BluetoothDeviceAgent& bluetoothDeviceAgent, std::string deviceId, std::string service, std::string characteristic, std::string bleInputProperty);
  winrt::fire_and_forget RequestMtuAsync(BluetoothDeviceAgent& bluetoothDeviceAgent, uint64_t expectedMtu);
  winrt::fire_and_forget WriteValueAsync(BluetoothDeviceAgent& bluetoothDeviceAgent, std::string deviceId, std::string service, std::string characteristic, std::vector<uint8_t> value, std::string bleOutputProperty);
  void SoterFlutterBluePlugin::GattCharacteristic_ValueChanged(GattCharacteristic sender, GattValueChangedEventArgs args);
};

// static
void SoterFlutterBluePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto method =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "soter_flutter_blue/method",
          &flutter::StandardMethodCodec::GetInstance());

  auto event_scan_result =
      std::make_unique<flutter::EventChannel<EncodableValue>>(
          registrar->messenger(), "soter_flutter_blue/event.scanResult",
          &flutter::StandardMethodCodec::GetInstance());
  auto message_connector_ =
      std::make_unique<flutter::BasicMessageChannel<EncodableValue>>(
          registrar->messenger(), "soter_flutter_blue/message.connector",
          &flutter::StandardMessageCodec::GetInstance());

  auto plugin = std::make_unique<SoterFlutterBluePlugin>();

  method->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  auto handler = std::make_unique<
      flutter::StreamHandlerFunctions<>>(
      [plugin_pointer = plugin.get()](
          const EncodableValue* arguments,
          std::unique_ptr<flutter::EventSink<>>&& events)
          -> std::unique_ptr<flutter::StreamHandlerError<>> {
        return plugin_pointer->OnListen(arguments, std::move(events));
      },
      [plugin_pointer = plugin.get()](const EncodableValue* arguments)
          -> std::unique_ptr<flutter::StreamHandlerError<>> {
        return plugin_pointer->OnCancel(arguments);
      });
  event_scan_result->SetStreamHandler(std::move(handler));

  plugin->message_connector_ = std::move(message_connector_);

  registrar->AddPlugin(std::move(plugin));
}

SoterFlutterBluePlugin::SoterFlutterBluePlugin() {
    InitializeAsync();
}

SoterFlutterBluePlugin::~SoterFlutterBluePlugin() {}

winrt::fire_and_forget SoterFlutterBluePlugin::InitializeAsync() {
  auto bluetoothAdapter = co_await BluetoothAdapter::GetDefaultAsync();
  bluetoothRadio = co_await bluetoothAdapter.GetRadioAsync();
}

void SoterFlutterBluePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

    auto method_name = method_call.method_name();
    OutputDebugString((L"SoterFlutterBlue: HandleMethodCall " + winrt::to_hstring(method_name) + L"\n").c_str());

    if (method_name.compare("isBluetoothAvailable") == 0) {
      result->Success(EncodableValue(bluetoothRadio && bluetoothRadio.State() == RadioState::On));
    } else if (method_name.compare("startScan") == 0) {
      if (!bluetoothLEWatcher) {
        bluetoothLEWatcher = BluetoothLEAdvertisementWatcher();
        bluetoothLEWatcherReceivedToken = bluetoothLEWatcher.Received({ this, &SoterFlutterBluePlugin::BluetoothLEWatcher_Received });
      }

      bluetoothLEWatcher.ScanningMode(BluetoothLEScanningMode::Active);
      bluetoothLEWatcher.Start();

      result->Success(nullptr);
    } else if (method_name.compare("stopScan") == 0) {
      if (bluetoothLEWatcher) {
        bluetoothLEWatcher.Stop();
        bluetoothLEWatcher.Received(bluetoothLEWatcherReceivedToken);
      }
      bluetoothLEWatcher = nullptr;
      result->Success(nullptr);
    } else if (method_name.compare("connect") == 0) {
      auto args = std::get<EncodableMap>(*method_call.arguments());
      auto deviceId = std::get<std::string>(args[EncodableValue("deviceId")]);
      ConnectAsync(std::stoull(deviceId));
      result->Success(nullptr);
    } else if (method_name.compare("disconnect") == 0) {
      //auto args = std::get<EncodableMap>(*method_call.arguments());
      //auto deviceId = std::get<std::string>(args[EncodableValue("deviceId")]);
      DisconnectAllDevices();
      result->Success(nullptr);
    } else if (method_name.compare("discoverServices") == 0) {
      auto args = std::get<EncodableMap>(*method_call.arguments());
      auto deviceId = std::get<std::string>(args[EncodableValue("deviceId")]);
      DiscoverServicesAsync(std::stoull(deviceId), deviceId);

      result->Success(nullptr);
    } else if (method_name.compare("setNotifiable") == 0) {
      auto args = std::get<EncodableMap>(*method_call.arguments());
      auto deviceId = std::get<std::string>(args[EncodableValue("deviceId")]);
      auto service = std::get<std::string>(args[EncodableValue("service")]);
      auto characteristic = std::get<std::string>(args[EncodableValue("characteristic")]);
      auto bleInputProperty = std::get<std::string>(args[EncodableValue("bleInputProperty")]);

      auto it = connectedDevices.find(std::stoull(deviceId));
      if (it == connectedDevices.end()) {
        result->Error("IllegalArgument", "Unknown devicesId:" + deviceId);
        return;
      }

      SetNotifiableAsync(*it->second, deviceId, service, characteristic, bleInputProperty);
      result->Success(nullptr);
    } else if (method_name.compare("requestMtu") == 0) {
      auto args = std::get<EncodableMap>(*method_call.arguments());
      auto deviceId = std::get<std::string>(args[EncodableValue("deviceId")]);
      auto expectedMtu = std::get<int32_t>(args[EncodableValue("expectedMtu")]);
      auto it = connectedDevices.find(std::stoull(deviceId));
      if (it == connectedDevices.end()) {
        result->Error("IllegalArgument", "Unknown devicesId:" + deviceId);
        return;
      }

      RequestMtuAsync(*it->second, expectedMtu);
      result->Success(nullptr);
    } else if (method_name.compare("writeValue") == 0) {
      auto args = std::get<EncodableMap>(*method_call.arguments());
      auto deviceId = std::get<std::string>(args[EncodableValue("deviceId")]);
      auto service = std::get<std::string>(args[EncodableValue("service")]);
      auto characteristic = std::get<std::string>(args[EncodableValue("characteristic")]);
      auto value = std::get<std::vector<uint8_t>>(args[EncodableValue("value")]);
      auto bleOutputProperty = std::get<std::string>(args[EncodableValue("bleOutputProperty")]);

      auto it = connectedDevices.find(std::stoull(deviceId));
      if (it == connectedDevices.end()) {
        result->Error("IllegalArgument", "Unknown devicesId:" + deviceId);
        return;
      }

      WriteValueAsync(*it->second, deviceId, service, characteristic, value, bleOutputProperty);
      result->Success(nullptr);
    } else if(method_name.compare("connectedDevices") == 0) {
      EncodableList mDevices = {};
      std::map<uint64_t, std::unique_ptr<BluetoothDeviceAgent>>::iterator it;
      for (it = connectedDevices.begin(); it != connectedDevices.end(); it++){

              mDevices.push_back(EncodableMap{
                  {"name", winrt::to_string(it->second->device.Name())},
                  {"bluetoothAddress", std::to_string(it->second->device.BluetoothAddress())},
                  {"deviceId", winrt::to_string(it->second->device.DeviceId())}, //it->second->device.DeviceId()
              });
      }
      result->Success(mDevices);
    } else {
      result->NotImplemented();
    }
}

std::vector<uint8_t> parseManufacturerData(BluetoothLEAdvertisement advertisement)
{
  if (advertisement.ManufacturerData().Size() == 0)
    return std::vector<uint8_t>();

  auto manufacturerData = advertisement.ManufacturerData().GetAt(0);
  // FIXME Compat with REG_DWORD_BIG_ENDIAN
  uint8_t* prefix = uint16_t_union{ manufacturerData.CompanyId() }.bytes;
  auto result = std::vector<uint8_t>{ prefix, prefix + sizeof(uint16_t_union) };

  auto data = to_bytevc(manufacturerData.Data());
  result.insert(result.end(), data.begin(), data.end());
  return result;
}

void SoterFlutterBluePlugin::BluetoothLEWatcher_Received(
    BluetoothLEAdvertisementWatcher sender,
    BluetoothLEAdvertisementReceivedEventArgs args) {
  OutputDebugString(L"SoterFlutterBlue: scanned something");
  auto manufacturer_data = parseManufacturerData(args.Advertisement());

  if(message_connector_){
        message_connector_->Send(EncodableMap{
            {"scanResult", true},
            {"name", winrt::to_string(args.Advertisement().LocalName())},
            {"deviceId", std::to_string(args.BluetoothAddress())},
            {"manufacturerData", manufacturer_data},
            {"rssi", args.RawSignalStrengthInDBm()},
        });
  }
}

void SoterFlutterBluePlugin::OnAdvertisementStopped (
    BluetoothLEAdvertisementWatcher sender,
    BluetoothLEAdvertisementWatcherStoppedEventArgs  args) {

    bluetoothLEWatcher.Received(bluetoothLEWatcherReceivedToken);
}

std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> SoterFlutterBluePlugin::OnListenInternal(
    const EncodableValue* arguments, std::unique_ptr<flutter::EventSink<EncodableValue>>&& events)
{
  // empty method
  return nullptr;
}

std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> SoterFlutterBluePlugin::OnCancelInternal(
    const EncodableValue* arguments)
{
  // empty method
  return nullptr;
}

winrt::fire_and_forget SoterFlutterBluePlugin::DiscoverServicesAsync(uint64_t bluetoothAddress, std::string deviceId) {
    auto device = co_await BluetoothLEDevice::FromBluetoothAddressAsync(bluetoothAddress);
    auto servicesResult = co_await device.GetGattServicesAsync();
    auto deviceMacAddress = std::to_string(bluetoothAddress);
    if (servicesResult.Status() != GattCommunicationStatus::Success) {
        message_connector_->Send(EncodableMap{
            {"DiscoverServicesState", "Failure"},
            {"deviceId", deviceMacAddress},
        });
        co_return;
    }
    EncodableList services = {};
    for (auto s : servicesResult.Services()){
        EncodableList characteristics = {};
        auto serviceId = to_uuidstr(s.Uuid());
        auto characteristicsResult = co_await s.GetCharacteristicsAsync();


        if(characteristicsResult.Status() != GattCommunicationStatus::Success){
            continue;
        }

        for(auto ch : characteristicsResult.Characteristics()) {

            auto readResult = co_await ch.ReadValueAsync();
            if(readResult.Status() != GattCommunicationStatus::Success){
                OutputDebugString((L"Khamidjon: characteristic value read ERROR for: " + winrt::to_hstring(to_uuidstr(ch.Uuid())) + L"\n").c_str());
                characteristics.push_back(EncodableMap{
                    {"uuid", to_uuidstr(ch.Uuid())},
                    {"deviceId", deviceMacAddress},
                    {"serviceUuid", serviceId},
                    {"value", {}},
                });
            } else {
                auto bytes = to_bytevc(readResult.Value());

                characteristics.push_back(EncodableMap{
                        {"uuid", to_uuidstr(ch.Uuid())},
                        {"deviceId", deviceMacAddress},
                        {"serviceUuid", serviceId},
                        {"value", bytes},
                });
            }
        }


        services.push_back(EncodableMap{
            {"uuid", serviceId},
            {"deviceId", deviceMacAddress},
            {"characteristics", characteristics},
        });
    }



    EncodableMap response = EncodableMap{
        {"DiscoverServicesState", "Success"},
        {"deviceId", std::to_string(bluetoothAddress)},
        {"services", services},
    };

    message_connector_->Send(response);
}

winrt::fire_and_forget SoterFlutterBluePlugin::ConnectAsync(uint64_t bluetoothAddress) {
  auto device = co_await BluetoothLEDevice::FromBluetoothAddressAsync(bluetoothAddress);
  auto servicesResult = co_await device.GetGattServicesAsync();
  if (servicesResult.Status() != GattCommunicationStatus::Success) {
    message_connector_->Send(EncodableMap{
      {"deviceId", std::to_string(bluetoothAddress)},
      {"ConnectionRequestState", "disconnected"},
    });
    co_return;
  }
  auto connnectionStatusChangedToken = device.ConnectionStatusChanged({ this, &SoterFlutterBluePlugin::BluetoothLEDevice_ConnectionStatusChanged });
  auto deviceAgent = std::make_unique<BluetoothDeviceAgent>(device, connnectionStatusChangedToken);
  auto pair = std::make_pair(bluetoothAddress, std::move(deviceAgent));
  connectedDevices.insert(std::move(pair));

  message_connector_->Send(EncodableMap{
    {"deviceId", std::to_string(bluetoothAddress)},
    {"ConnectionRequestState", "connected"},
  });
}

void SoterFlutterBluePlugin::BluetoothLEDevice_ConnectionStatusChanged(BluetoothLEDevice sender, IInspectable args) {
  if (sender.ConnectionStatus() == BluetoothConnectionStatus::Disconnected) {
    CleanConnection(sender.BluetoothAddress());
    message_connector_->Send(EncodableMap{
      {"deviceId", std::to_string(sender.BluetoothAddress())},
      {"ConnectionState", "disconnected"},
    });
  }
}

// https://github.com/jasongin/noble-uwp/issues/20
void SoterFlutterBluePlugin::DisconnectAllDevices(){
      std::map<uint64_t, std::unique_ptr<BluetoothDeviceAgent>>::iterator it;
      for (it = connectedDevices.begin(); it != connectedDevices.end(); it++)
      {
          // remove all value change tokens
          it->second->valueChangedTokens.clear();

          // todo this might be necessary if device is not disconnected
          // remove characteristic's value changed tokens
          //std::map<std::string, GattCharacteristic>::iterator itCh;
          //for(itCh=it->second->gattCharacteristics.begin(); itCh!=it->second->gattCharacteristics.end();itCh++){
          //      itCh->second.ValueChanged({});
          //}

          // clear current characteristics map to dispose objects
          it->second->gattCharacteristics.clear();

          // dispose of all services
          // remove characteristic's value changed tokens
          std::map<std::string, GattDeviceService>::iterator itS;
          for(itS=it->second->gattServices.begin(); itS!=it->second->gattServices.end();itS++){
                itS->second.Close();
                //itS->second.Dispose();
          }
          // clear current services map to dispose objects
          it->second->gattServices.clear();

          // remove device handlers and device itself
          // it->second->device.ConnectionStatusChanged = nullptr;
          it->second->device.Close();
          it->second->device = nullptr;
      }


      // remove all connected device
      connectedDevices.clear();
      message_connector_->Send(EncodableMap{
         {"DisconnectionRequestState", true},
      });
}


void SoterFlutterBluePlugin::CleanConnection(uint64_t bluetoothAddress) {
  auto node = connectedDevices.extract(bluetoothAddress);
  if (!node.empty()) {
    auto deviceAgent = std::move(node.mapped());
    deviceAgent->device.ConnectionStatusChanged(deviceAgent->connnectionStatusChangedToken);
    for (auto& tokenPair : deviceAgent->valueChangedTokens) {
      deviceAgent->gattCharacteristics.at(tokenPair.first).ValueChanged(tokenPair.second);
    }
  }
}

winrt::fire_and_forget SoterFlutterBluePlugin::RequestMtuAsync(BluetoothDeviceAgent& bluetoothDeviceAgent, uint64_t expectedMtu) {
  OutputDebugString(L"RequestMtuAsync expectedMtu\n");
  auto gattSession = co_await GattSession::FromDeviceIdAsync(bluetoothDeviceAgent.device.BluetoothDeviceId());
  message_connector_->Send(EncodableMap{
    {"mtuConfig", (int64_t)gattSession.MaxPduSize()},
  });
}

winrt::fire_and_forget SoterFlutterBluePlugin::SetNotifiableAsync(BluetoothDeviceAgent& bluetoothDeviceAgent, std::string deviceId, std::string service, std::string characteristic, std::string bleInputProperty) {
  auto gattCharacteristic = co_await bluetoothDeviceAgent.GetCharacteristicAsync(service, characteristic);
  auto descriptorValue = bleInputProperty == "notification" ? GattClientCharacteristicConfigurationDescriptorValue::Notify
    : bleInputProperty == "indication" ? GattClientCharacteristicConfigurationDescriptorValue::Indicate
    : GattClientCharacteristicConfigurationDescriptorValue::None;

  auto writeDescriptorStatus = co_await gattCharacteristic.WriteClientCharacteristicConfigurationDescriptorAsync(descriptorValue);
  if (writeDescriptorStatus != GattCommunicationStatus::Success){
    message_connector_->Send(EncodableMap{
       {"SetNotificationResponse", false},
       {"deviceId", deviceId},
    });
  } else {
    message_connector_->Send(EncodableMap{
       {"SetNotificationResponse", true},
       {"deviceId", deviceId},
    });
  }
  if (bleInputProperty != "disabled") {
    // TODO THIS WAS DIFFERENT IN THE ORIGINIAL SOURCE CODE BEFORE, FIXED POSSIBLE BUG BUT NEED TO BE CHECKED
    bluetoothDeviceAgent.valueChangedTokens[characteristic] = gattCharacteristic.ValueChanged({ this, &SoterFlutterBluePlugin::GattCharacteristic_ValueChanged });
  } else {
    // TODO POSSIBLE BUG -> VALUE CHANGED TOKEN ITSELF IS BEING ASSIGNED TO VALUECHANGED() AGAIN WHICH IS WRONG
    gattCharacteristic.ValueChanged(std::exchange(bluetoothDeviceAgent.valueChangedTokens[characteristic], {}));
  }
}

winrt::fire_and_forget SoterFlutterBluePlugin::WriteValueAsync(BluetoothDeviceAgent& bluetoothDeviceAgent, std::string deviceId, std::string service, std::string characteristic, std::vector<uint8_t> value, std::string bleOutputProperty) {
  auto gattCharacteristic = co_await bluetoothDeviceAgent.GetCharacteristicAsync(service, characteristic);
  GattCommunicationStatus result;

  OutputDebugString(L"started trying to write\n");
  if(bleOutputProperty == "withResponse") {
      result = co_await gattCharacteristic.WriteValueAsync(
                            from_bytevc(value),
                            GattWriteOption::WriteWithResponse
                        );
  } else {
      result = co_await gattCharacteristic.WriteValueAsync(
                            from_bytevc(value),
                            GattWriteOption::WriteWithoutResponse
                        );
  }


    message_connector_->Send(EncodableMap{
        {"WriteCharacteristicResponse", 0},
        {"deviceId", deviceId},
        {"serviceUuid", service},
        {"characteristicsUuid", characteristic},
        {"success", result==GattCommunicationStatus::Success},
    });
}

void SoterFlutterBluePlugin::GattCharacteristic_ValueChanged(GattCharacteristic sender, GattValueChangedEventArgs args) {
  auto uuid = to_uuidstr(sender.Uuid());
  auto serviceUuid = to_uuidstr(sender.Service().Uuid());
  auto bytes = to_bytevc(args.CharacteristicValue());
  message_connector_->Send(EncodableMap{
    {"characteristicChanged", true},
    {"deviceId", std::to_string(sender.Service().Device().BluetoothAddress())},
    {"serviceUuid", serviceUuid},
    {"characteristicUuid", uuid},
    {"value", bytes},
  });
};

}  // namespace

void SoterFlutterBluePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  SoterFlutterBluePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
