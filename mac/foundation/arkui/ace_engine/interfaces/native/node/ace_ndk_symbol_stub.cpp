/*
 * darwin port: 补齐 ace_ndk 缺失符号
 * - ResourceManager::GetInstance/GetResourceAdapter: 设备主库(libace)在运行时提供,
 *   NDK 静态链接场景提供空实现避免 -z defs 报错
 * - NodeModel::SetNodeAttribute(void 版): deprecated 接口, 转调 int32_t 版本
 */

#include "core/common/resource/resource_manager.h"
#include "interfaces/native/node/style_modifier.h"

namespace OHOS::Ace {
ResourceManager& ResourceManager::GetInstance()
{
    static ResourceManager instance;
    return instance;
}
} // namespace OHOS::Ace

namespace OHOS::Ace::NodeModel {
void SetNodeAttribute(ArkUI_NodeHandle node, ArkUI_NodeAttributeType type,
                      const char* value)
{
    ArkUI_AttributeItem item;
    item.string = value;
    SetNodeAttribute(node, type, &item);
}
} // namespace OHOS::Ace::NodeModel
