#import <Foundation/Foundation.h>
#import <string>

int main(int argc, char *argv[]) {
    
    @autoreleasepool {
        
        const unsigned short W = 256;
        const unsigned short H = 144;
        const float aspect = H/(float)W;
        
        NSString *path = @"./texture.png";
        
        if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            
            NSString *mimeType = nil;
            if([[path pathExtension] isEqualToString:@"png"]) mimeType = @"image/png";
            else if([[path pathExtension] isEqualToString:@"jpg"]||[[path pathExtension] isEqualToString:@"jpeg"]) mimeType = @"image/jpeg";
            
            if(mimeType) {
                
                NSMutableData *texture = [[NSMutableData alloc] init];
                [texture appendData:[[NSData alloc] initWithContentsOfFile:path]];
                
                // Aligned to 4-byte boundaries.
                while(texture.length%4!=0) {
                    [texture appendBytes:new const char[1]{0x20} length:1];
                }
                
                std::string JSON = R"({"asset":{"generator":"RC","version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"mesh":0}],"materials":[{"doubleSided":true,"pbrMetallicRoughness":{"baseColorTexture":{"index":0},"metallicFactor":0,"roughnessFactor":1.0}}],"meshes":[{"primitives":[{"attributes":{"POSITION":0,"TEXCOORD_0":1},"indices":2,"material":0}]}],"textures":[{"sampler":0,"source":0}],"images":[{"bufferView":3,"mimeType":"image/jpeg","name":"texture"}],"accessors":[{"bufferView":0,"componentType":5126,"count":0,"max":[0,0,0],"min":[0,0,0],"type":"VEC3"},{"bufferView":1,"componentType":5126,"count":0,"type":"VEC2"},{"bufferView":2,"componentType":5125,"count":0,"type":"SCALAR"}],"bufferViews":[{"buffer":0,"byteLength":0,"byteOffset":0},{"buffer":0,"byteLength":0,"byteOffset":0},{"buffer":0,"byteLength":0,"byteOffset":0},{"buffer":0,"byteLength":0,"byteOffset":0}],"samplers":[{"magFilter":9729,"minFilter":9987,"wrapS":33071,"wrapT":33071}],"buffers":[{"byteLength":0}]})";
                
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[[NSString stringWithUTF8String:JSON.c_str()] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
                
                if(dict) {
                    
                    std::vector<float> v;
                    std::vector<float> vt;
                    std::vector<unsigned int> f;
                    
                    for(int i=0; i<H; i++) {
                        for(int j=0; j<W; j++) {
                            
                            float tx = j/(float)(W-1);
                            float ty = i/(float)(H-1);
                                
                            float vx = (tx*2.0-1.0);
                            float vy = (ty*2.0-1.0)*aspect;
                            float vz = 0.0;
                            
                            v.push_back(vx);
                            v.push_back(vy);
                            v.push_back(vz);
                            
                            vt.push_back(tx);
                            vt.push_back(1.0-ty);
                        }
                    }
                    
                    for(int i=0; i<H-1; i++) {
                        for(int j=0; j<W-1; j++) {
                            
                            int a = i*W+j;
                            int b = i*W+(j+1);
                            int c = (i+1)*W+j;
                            
                            f.push_back(a);
                            f.push_back(b);
                            f.push_back(c);
                            
                            a = i*W+(j+1);
                            b = (i+1)*W+(j+1);
                            
                            f.push_back(a);
                            f.push_back(b);
                            f.push_back(c);
                        }
                    }
                    
                    float v_min[3] = {v[0],v[1],v[2]};
                    float v_max[3] = {v[0],v[1],v[2]};
                    
                    for(int n=1; n<v.size()/3; n++) {
                        
                        unsigned int addr = n*3;
                        
                        v_min[0] = std::min(v_min[0],v[addr+0]);
                        v_max[0] = std::max(v_max[0],v[addr+0]);
                        
                        v_min[1] = std::min(v_min[1],v[addr+1]);
                        v_max[1] = std::max(v_max[1],v[addr+1]);
                        
                        v_min[2] = std::min(v_min[2],v[addr+2]);
                        v_max[2] = std::max(v_max[2],v[addr+2]);
                    }
                    
                    unsigned int offset = 0;
                    
                    dict[@"images"][0][@"mimeType"] = mimeType;

                    dict[@"bufferViews"][0][@"byteOffset"] = [NSNumber numberWithInt:offset];
                    dict[@"bufferViews"][0][@"byteLength"] = [NSNumber numberWithInt:v.size()*sizeof(float)];
                    
                    for(int n=0; n<3; n++) {
                        dict[@"accessors"][0][@"min"][n] = [NSNumber numberWithFloat:v_min[n]];
                        dict[@"accessors"][0][@"max"][n] = [NSNumber numberWithFloat:v_max[n]];
                    }
                                        
                    dict[@"accessors"][0][@"count"] = [NSNumber numberWithInt:v.size()/3];
                    offset+=v.size()*sizeof(float);
                    
                    dict[@"bufferViews"][1][@"byteOffset"] = [NSNumber numberWithInt:offset];
                    dict[@"bufferViews"][1][@"byteLength"] = [NSNumber numberWithInt:vt.size()*sizeof(float)];
                    dict[@"accessors"][1][@"count"] = [NSNumber numberWithInt:vt.size()/2];
                    offset+=vt.size()*sizeof(float);
                    
                    dict[@"bufferViews"][2][@"byteOffset"] = [NSNumber numberWithInt:offset];
                    dict[@"bufferViews"][2][@"byteLength"] = [NSNumber numberWithInt:f.size()*sizeof(unsigned int)];
                    dict[@"accessors"][2][@"count"] = [NSNumber numberWithInt:f.size()];
                    offset+=f.size()*sizeof(unsigned int);
                    
                    dict[@"bufferViews"][3][@"byteOffset"] = [NSNumber numberWithInt:offset];
                    dict[@"bufferViews"][3][@"byteLength"] = [NSNumber numberWithInt:texture.length];
                    offset+=texture.length;
                    
                    dict[@"buffers"][0][@"byteLength"] = [NSNumber numberWithInt:offset];
                    
                    NSMutableData *json = [[NSMutableData alloc] init];
                    [json appendData:[NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingWithoutEscapingSlashes|NSJSONWritingSortedKeys error:nil]];
                    
                    // Aligned to 4-byte boundaries.
                    while(json.length%4!=0) {
                        [json appendBytes:new const char[1]{0x20} length:1];
                    }
                    
                    NSMutableData *glb = [[NSMutableData alloc] init];
                    [glb appendBytes:new const char[4]{'g','l','T','F'} length:4];
                    [glb appendBytes:new unsigned int[1]{2} length:4];
                    [glb appendBytes:new unsigned int[1]{((4*7)+(unsigned int)json.length)+offset} length:4];
                    
                    [glb appendBytes:new unsigned int[1]{(unsigned int)json.length} length:4];
                    [glb appendBytes:new const char[4]{'J','S','O','N'} length:4];
                                        
                    [glb appendBytes:json.bytes length:json.length];
                    [glb appendBytes:new unsigned int[1]{offset} length:4];
                    [glb appendBytes:new const char[4]{'B','I','N',0} length:4];
                    [glb appendBytes:v.data() length:v.size()*sizeof(float)];
                    [glb appendBytes:vt.data() length:vt.size()*sizeof(float)];
                    [glb appendBytes:f.data() length:f.size()*sizeof(unsigned int)];
                    [glb appendBytes:texture.bytes length:texture.length];
                    
                    [glb writeToFile:@"./mesh.glb" atomically:YES];
                    
                    glb = nil;
                    json = nil;
                    dict = nil;
                    texture = nil;

                    v.clear();
                    v.shrink_to_fit();
                    vt.clear();
                    vt.shrink_to_fit();
                    f.clear();
                    f.shrink_to_fit();
                }
            }
        }
    }
}