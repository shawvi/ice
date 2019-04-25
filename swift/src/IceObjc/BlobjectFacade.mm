//
// Copyright (c) ZeroC, Inc. All rights reserved.
//

#import "BlobjectFacade.h"
#import "ObjectAdapter.h"
#import "Util.h"

#import "InputStream.h"
#import "Connection.h"

void
BlobjectFacade::ice_invokeAsync(std::pair<const Byte*, const Byte*> inEncaps,
                                         std::function<void(bool, const std::pair<const Byte*, const Byte*>&)> response,
                                         std::function<void(std::exception_ptr)> error,
                                         const Ice::Current& current)
{
   ICEBlobjectResponse responseCallback = ^(bool ok, const void* outParams, size_t outSize) {
        const Ice::Byte* start = reinterpret_cast<const Ice::Byte*>(outParams);
        response(ok, std::make_pair(start, start + outSize));
    };

    ICEBlobjectException exceptionCallback = ^(ICERuntimeException* e) {
        error(convertException(e));
    };

    // Copy the bytes
    std::vector<Ice::Byte> inBytes(inEncaps.first, inEncaps.second);

    ICEObjectAdapter* adapter = createLocalObject(current.adapter, [&current] () -> id
                                                  {
                                                      return [[ICEObjectAdapter alloc] initWithCppObjectAdapter:current.adapter];
                                                  });
    ICEConnection* con = createLocalObject(current.con, [&current] () -> id
                                           {
                                               return [[ICEConnection alloc] initWithCppConnection: current.con];
                                           });

    [_facade facadeInvoke:adapter
                       is:[[ICEInputStream alloc] initWithBytes:std::move(inBytes)]
                      con: con
                     name:toNSString(current.id.name) category:toNSString(current.id.category)
                    facet:toNSString(current.facet)
                operation:toNSString(current.operation)
                     mode:static_cast<uint8_t>(current.mode)
                  context:toNSDictionary(current.ctx)
                requestId:current.requestId
            encodingMajor:current.encoding.major
            encodingMinor:current.encoding.minor
                 response:responseCallback
                exception:exceptionCallback];
}