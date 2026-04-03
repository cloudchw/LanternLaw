// entry/src/main/ets/utils/PasswordHelper.ets

/**
 * 密码工具类
 * Password Helper - SHA-256 哈希与验证
 */
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';

const SALT = 'LanternLaw_2026_Salt';
const textEncoder = new util.TextEncoder();

/**
 * 对密码进行 SHA-256 哈希
 */
export async function hashPassword(password: string): Promise<string> {
  const md = cryptoFramework.createMd('SHA256');
  const data = textEncoder.encodeInto(password + SALT);
  await md.update({ data: data });
  const hashData = await md.digest();
  return Array.from(hashData.data).map(b => b.toString(16).padStart(2, '0')).join('');
}

/**
 * 验证密码是否匹配哈希值
 */
export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  const computedHash = await hashPassword(password);
  return computedHash === hash;
}

/**
 * 验证用户名格式
 * @returns 错误信息，空字符串表示验证通过
 */
export function validateUsername(username: string): string {
  if (!username || username.trim().length === 0) {
    return '请输入用户名';
  }
  if (username.trim().length < 2) {
    return '用户名至少需要2个字符';
  }
  if (username.trim().length > 12) {
    return '用户名最多12个字符';
  }
  return '';
}

/**
 * 验证密码格式
 * @returns 错误信息，空字符串表示验证通过
 */
export function validatePassword(password: string): string {
  if (!password || password.length === 0) {
    return '请输入密码';
  }
  if (password.length < 6) {
    return '密码至少需要6个字符';
  }
  if (password.length > 20) {
    return '密码最多20个字符';
  }
  return '';
}
