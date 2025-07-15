/*
 * Schism Tracker - a cross-platform Impulse Tracker clone
 * copyright (c) 2003-2005 Storlek <storlek@rigelseven.com>
 * copyright (c) 2005-2008 Mrs. Brisby <mrs.brisby@nimh.org>
 * copyright (c) 2009 Storlek & Mrs. Brisby
 * copyright (c) 2010-2012 Storlek
 * URL: http://schismtracker.org/
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
#include "utils.h"

unsigned int enable(void)
{
  unsigned int res = macosx_ibook_fnswitch(kfntheOtherMode);
  CFPreferencesSetAppValue( CFSTR("fnState"), kCFBooleanTrue, CFSTR("com.apple.keyboard") );
  CFPreferencesAppSynchronize( CFSTR("com.apple.keyboard") );
  
  NSDictionary *dict = @{@"state": @YES};
  [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.apple.keyboard.fnstatedidchange" object:NULL userInfo:dict deliverImmediately:YES];
  
  return res;
}

unsigned int disable(void)
{
  unsigned int res = macosx_ibook_fnswitch(kfnAppleMode);
  CFPreferencesSetAppValue( CFSTR("fnState"), kCFBooleanFalse, CFSTR("com.apple.keyboard") );
  CFPreferencesAppSynchronize( CFSTR("com.apple.keyboard") );
  
  NSDictionary *dict = @{@"state": @NO};
  [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.apple.keyboard.fnstatedidchange" object:NULL userInfo:dict deliverImmediately:YES];
  
  return res;
}

int macosx_ibook_fnswitch(int setting)
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
