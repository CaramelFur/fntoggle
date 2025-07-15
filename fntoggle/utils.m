#include "utils.h"

unsigned int enable(void)
{
  unsigned int res = setFnState(kfntheOtherMode);
  CFPreferencesSetAppValue( CFSTR("fnState"), kCFBooleanTrue, CFSTR("com.apple.keyboard") );
  CFPreferencesAppSynchronize( CFSTR("com.apple.keyboard") );
  
  NSDictionary *dict = @{@"state": @YES};
  [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.apple.keyboard.fnstatedidchange" object:NULL userInfo:dict deliverImmediately:YES];
  
  return res;
}

unsigned int disable(void)
{
  unsigned int res = setFnState(kfnAppleMode);
  CFPreferencesSetAppValue( CFSTR("fnState"), kCFBooleanFalse, CFSTR("com.apple.keyboard") );
  CFPreferencesAppSynchronize( CFSTR("com.apple.keyboard") );
  
  NSDictionary *dict = @{@"state": @NO};
  [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.apple.keyboard.fnstatedidchange" object:NULL userInfo:dict deliverImmediately:YES];
  
  return res;
}

int setFnState(int setting)
{
  kern_return_t ret;
  
  CFDictionaryRef classToMatch = IOServiceMatching(kIOHIDSystemClass);
  if (classToMatch == NULL) return -1;
  
  io_iterator_t io_iterator;
  ret = IOServiceGetMatchingServices(kIOMainPortDefault, classToMatch, &io_iterator);
  if (ret != KERN_SUCCESS) return -1;
  
  io_service_t io_service;
  io_service = IOIteratorNext(io_iterator);
  IOObjectRelease(io_iterator);
  
  if (!io_service) return -1;
  
  io_connect_t io_connect;
  ret = IOServiceOpen(io_service, mach_task_self(), kIOHIDParamConnectType, &io_connect);
  if (ret != KERN_SUCCESS) return -1;
  
  if (setting == kfnAppleMode || setting == kfntheOtherMode) {
    CFNumberRef wrappedSetting = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &setting);
    ret = IOHIDSetCFTypeParameter(io_connect,
                                  CFSTR(kIOHIDFKeyModeKey),
                                  wrappedSetting);
    if (ret != KERN_SUCCESS) {
      IOServiceClose(io_connect);
      return -1;
    }
  }
  
  IOServiceClose(io_connect);
  return 0;
}
