local wez = require('wezterm')

-- Platform detection section
local function is_found(str, pattern)
   return string.find(str, pattern) ~= nil
end

---@alias PlatformType 'windows' | 'linux' | 'mac'

---@return {os: PlatformType, is_win: boolean, is_linux: boolean, is_mac: boolean}
local function platform()
   local is_win = is_found(wez.target_triple, 'windows')
   local is_linux = is_found(wez.target_triple, 'linux')
   local is_mac = is_found(wez.target_triple, 'apple')
   local os

   if is_win then
      os = 'windows'
   elseif is_linux then
      os = 'linux'
   elseif is_mac then
      os = 'mac'
   else
      error('Unknown platform')
   end

   return {
      os = os,
      is_win = is_win,
      is_linux = is_linux,
      is_mac = is_mac,
   }
end

local _platform = platform()

-- GPU Adapter section
---@alias wezGPUBackend 'Vulkan'|'Metal'|'Gl'|'Dx12'
---@alias wezGPUDeviceType 'DiscreteGpu'|'IntegratedGpu'|'Cpu'|'Other'

---@class wezGPUAdapter
---@field name string
---@field backend wezGPUBackend
---@field device number
---@field device_type wezGPUDeviceType
---@field driver? string
---@field driver_info? string
---@field vendor string

---@alias AdapterMap { [wezGPUBackend]: wezGPUAdapter|nil }|nil

---@class GpuAdapters
---@field __backends wezGPUBackend[]
---@field __preferred_backend wezGPUBackend
---@field __preferred_device_type wezGPUDeviceType
---@field DiscreteGpu AdapterMap
---@field IntegratedGpu AdapterMap
---@field Cpu AdapterMap
---@field Other AdapterMap
local GpuAdapters = {}
GpuAdapters.__index = GpuAdapters

---See `https://github.com/gfx-rs/wgpu#supported-platforms` for more info on available backends
GpuAdapters.AVAILABLE_BACKENDS = {
   windows = { 'Dx12', 'Vulkan', 'Gl' },
   linux = { 'Vulkan', 'Gl' },
   mac = { 'Metal' },
}

---@type wezGPUAdapter[]
GpuAdapters.ENUMERATED_GPUS = wez.gui.enumerate_gpus()

---@return GpuAdapters
---@private
function GpuAdapters:init()
   local initial = {
      __backends = self.AVAILABLE_BACKENDS[_platform.os],
      __preferred_backend = self.AVAILABLE_BACKENDS[_platform.os][1],
      DiscreteGpu = nil,
      IntegratedGpu = nil,
      Cpu = nil,
      Other = nil,
   }

   -- iterate over the enumerated GPUs and create a lookup table (`AdapterMap`)
   for _, adapter in ipairs(self.ENUMERATED_GPUS) do
      if not initial[adapter.device_type] then
         initial[adapter.device_type] = {}
      end
      initial[adapter.device_type][adapter.backend] = adapter
   end

   local gpu_adapters = setmetatable(initial, self)

   return gpu_adapters
end

---Will pick the best adapter based on the following criteria:
---   1. Best GPU available (Discrete > Integrated > Other (for wgpu's OpenGl implementation on Discrete GPU) > Cpu)
---   2. Best graphics API available (based off my very scientific scroll a big log file in neovim test 😁)
---
---Graphics API choices are based on the platform:
---   - Windows: Dx12 > Vulkan > OpenGl
---   - Linux: Vulkan > OpenGl
---   - Mac: Metal
---@see GpuAdapters.AVAILABLE_BACKENDS
---
---If the best adapter combo is not found, it will return `nil` and lets wez decide the best adapter.
---
---Please note these are my own personal preferences and may not be the best for your system.
---If you want to manually choose the adapter, use `GpuAdapters:pick_manual(backend, device_type)`
---Or feel free to re-arrange `GpuAdapters.AVAILABLE_BACKENDS` to you liking
---@return wezGPUAdapter|nil
function GpuAdapters:pick_best()
   local adapters_options = self.DiscreteGpu
   local preferred_backend = self.__preferred_backend

   if not adapters_options then
      adapters_options = self.IntegratedGpu
   end

   if not adapters_options then
      adapters_options = self.Other
      preferred_backend = 'Gl'
   end

   if not adapters_options then
      adapters_options = self.Cpu
   end

   if not adapters_options then
      wez.log_error('No GPU adapters found. Using Default Adapter.')
      return nil
   end

   local adapter_choice = adapters_options[preferred_backend]

   if not adapter_choice then
      wez.log_error('Preferred backend not available. Using Default Adapter.')
      return nil
   end

   return adapter_choice
end

---Manually pick the adapter based on the backend and device type.
---If the adapter is not found, it will return nil and lets wez decide the best adapter.
---@param backend wezGPUBackend
---@param device_type wezGPUDeviceType
---@return wezGPUAdapter|nil
function GpuAdapters:pick_manual(backend, device_type)
   local adapters_options = self[device_type]

   if not adapters_options then
      wez.log_error('No GPU adapters found. Using Default Adapter.')
      return nil
   end

   local adapter_choice = adapters_options[backend]

   if not adapter_choice then
      wez.log_error('Preferred backend not available. Using Default Adapter.')
      return nil
   end

   return adapter_choice
end

-- Export both platform and GPU functions
_platform.gpu_adapters = GpuAdapters:init()

return _platform
