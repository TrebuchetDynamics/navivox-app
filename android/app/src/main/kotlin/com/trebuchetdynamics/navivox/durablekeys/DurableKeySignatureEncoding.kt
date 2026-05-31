package com.trebuchetdynamics.navivox.durablekeys

import java.math.BigInteger
import java.util.Base64

object DurableKeySignatureEncoding {
    fun derToJose(der: ByteArray): ByteArray {
        if (der.size < 8 || der[0] != 0x30.toByte()) {
            throw IllegalArgumentException("Invalid DER ECDSA signature")
        }
        var offset = 1
        val sequenceLength = readLength(der, offset)
        offset += sequenceLength.bytesRead
        if (sequenceLength.length != der.size - offset) {
            throw IllegalArgumentException("Invalid DER ECDSA sequence length")
        }
        val r = readInteger(der, offset)
        offset = r.nextOffset
        val s = readInteger(der, offset)
        if (s.nextOffset != der.size) {
            throw IllegalArgumentException("Unexpected trailing DER bytes")
        }
        return toFixedWidth(r.value) + toFixedWidth(s.value)
    }

    private fun readInteger(der: ByteArray, offset: Int): IntegerResult {
        if (offset >= der.size || der[offset] != 0x02.toByte()) {
            throw IllegalArgumentException("Invalid DER ECDSA integer")
        }
        val length = readLength(der, offset + 1)
        val valueStart = offset + 1 + length.bytesRead
        val valueEnd = valueStart + length.length
        if (valueEnd > der.size || length.length <= 0) {
            throw IllegalArgumentException("Invalid DER ECDSA integer length")
        }
        return IntegerResult(
            value = der.copyOfRange(valueStart, valueEnd),
            nextOffset = valueEnd,
        )
    }

    private fun readLength(der: ByteArray, offset: Int): LengthResult {
        if (offset >= der.size) throw IllegalArgumentException("Missing DER length")
        val first = der[offset].toInt() and 0xff
        if (first and 0x80 == 0) return LengthResult(first, 1)
        val byteCount = first and 0x7f
        if (byteCount == 0 || byteCount > 2 || offset + byteCount >= der.size) {
            throw IllegalArgumentException("Invalid DER length")
        }
        var length = 0
        repeat(byteCount) { index ->
            length = (length shl 8) or (der[offset + 1 + index].toInt() and 0xff)
        }
        return LengthResult(length, 1 + byteCount)
    }

    fun p256CoordinateToBase64Url(value: BigInteger): String {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(value.toFixedWidth())
    }

    private fun toFixedWidth(value: ByteArray): ByteArray {
        return BigInteger(1, value).toFixedWidth()
    }

    private fun BigInteger.toFixedWidth(): ByteArray {
        val unsigned = toByteArray().dropWhile { it == 0.toByte() }.toByteArray()
        if (unsigned.size > 32) {
            throw IllegalArgumentException("P-256 integer is too large")
        }
        return ByteArray(32 - unsigned.size) + unsigned
    }

    private data class LengthResult(val length: Int, val bytesRead: Int)
    private data class IntegerResult(val value: ByteArray, val nextOffset: Int)
}
