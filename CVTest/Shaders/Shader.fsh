//
//  Shader.fsh
//  CVTest
//
//  Created by Michael Ilich on 2013-01-11.
//  Copyright (c) 2013 Sarofax. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
