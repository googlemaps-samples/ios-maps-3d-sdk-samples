// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Compatibility shims for SwiftUI symbols referenced by GooglePlacesSwift 11.2.0 binary
#if defined(__arm64__)

.text
.globl _$s7SwiftUI14_TaskModifier2V4name18executorPreference8priority6actionACSS_Sch_pSgScPyyYaYAcntcfC
.p2align 2
_$s7SwiftUI14_TaskModifier2V4name18executorPreference8priority6actionACSS_Sch_pSgScPyyYaYAcntcfC:
    ret

.globl _$s7SwiftUI14_TaskModifier2VMa
.p2align 2
_$s7SwiftUI14_TaskModifier2VMa:
    ret

.globl _$s7SwiftUI19_TaskValueModifier2V2id4name18executorPreference8priority6actionACyxGx_SSSch_pSgScPyyYaYAcntcfC
.p2align 2
_$s7SwiftUI19_TaskValueModifier2V2id4name18executorPreference8priority6actionACyxGx_SSSch_pSgScPyyYaYAcntcfC:
    ret

.globl _$s7SwiftUI19_TaskValueModifier2VMa
.p2align 2
_$s7SwiftUI19_TaskValueModifier2VMa:
    ret

.data
.globl _$s7SwiftUI14_TaskModifier2VAA12ViewModifierAAMc
.p2align 3
_$s7SwiftUI14_TaskModifier2VAA12ViewModifierAAMc:
    .quad 0

.globl _$s7SwiftUI14_TaskModifier2VMn
.p2align 3
_$s7SwiftUI14_TaskModifier2VMn:
    .quad 0

.globl _$s7SwiftUI19_TaskValueModifier2VMn
.p2align 3
_$s7SwiftUI19_TaskValueModifier2VMn:
    .quad 0

.globl _$s7SwiftUI19_TaskValueModifier2VyxGAA12ViewModifierAAMc
.p2align 3
_$s7SwiftUI19_TaskValueModifier2VyxGAA12ViewModifierAAMc:
    .quad 0

#elif defined(__x86_64__)

.text
.globl _$s7SwiftUI14_TaskModifier2V4name18executorPreference8priority6actionACSS_Sch_pSgScPyyYaYAcntcfC
_$s7SwiftUI14_TaskModifier2V4name18executorPreference8priority6actionACSS_Sch_pSgScPyyYaYAcntcfC:
    retq

.globl _$s7SwiftUI14_TaskModifier2VMa
_$s7SwiftUI14_TaskModifier2VMa:
    retq

.globl _$s7SwiftUI19_TaskValueModifier2V2id4name18executorPreference8priority6actionACyxGx_SSSch_pSgScPyyYaYAcntcfC
_$s7SwiftUI19_TaskValueModifier2V2id4name18executorPreference8priority6actionACyxGx_SSSch_pSgScPyyYaYAcntcfC:
    retq

.globl _$s7SwiftUI19_TaskValueModifier2VMa
_$s7SwiftUI19_TaskValueModifier2VMa:
    retq

.data
.globl _$s7SwiftUI14_TaskModifier2VAA12ViewModifierAAMc
.p2align 3
_$s7SwiftUI14_TaskModifier2VAA12ViewModifierAAMc:
    .quad 0

.globl _$s7SwiftUI14_TaskModifier2VMn
.p2align 3
_$s7SwiftUI14_TaskModifier2VMn:
    .quad 0

.globl _$s7SwiftUI19_TaskValueModifier2VMn
.p2align 3
_$s7SwiftUI19_TaskValueModifier2VMn:
    .quad 0

.globl _$s7SwiftUI19_TaskValueModifier2VyxGAA12ViewModifierAAMc
.p2align 3
_$s7SwiftUI19_TaskValueModifier2VyxGAA12ViewModifierAAMc:
    .quad 0

#endif
