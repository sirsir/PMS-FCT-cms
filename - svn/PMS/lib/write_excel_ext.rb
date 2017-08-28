class Workbook < BIFFWriter

  ###############################################################################
  #
  # _add_mso_drawing_group_continue()
  #
  # See first the Spreadsheet::WriteExcel::BIFFwriter::_add_continue() method.
  #
  # Add specialised CONTINUE headers to large MSODRAWINGGROUP data block.
  # We use the Excel 97 max block size of 8228 - 4 bytes for the header = 8224.
  #
  # The structure depends on the size of the data block:
  #
  #     Case 1:  <=   8224 bytes      1 MSODRAWINGGROUP
  #     Case 2:  <= 2*8224 bytes      1 MSODRAWINGGROUP + 1 CONTINUE
  #     Case 3:  >  2*8224 bytes      2 MSODRAWINGGROUP + n CONTINUE
  #
  def add_mso_drawing_group_continue(data)
    limit       = 8228 -4
    mso_group   = 0x00EB # Record identifier
    continue    = 0x003C # Record identifier
    block_count = 1

    # Ignore the base class _add_continue() method.
    @ignore_continue = 1

    # Case 1 above. Just return the data as it is.
    if data.length <= limit
      append(data)
      return
    end

    # Change length field of the first MSODRAWINGGROUP block. Case 2 and 3.
    tmp = data.dup[0, limit + 4]
    data[0, limit + 4] = ''
    tmp[2, 2] = [limit].pack('v')
    append(tmp)

    # Add MSODRAWINGGROUP and CONTINUE blocks for Case 3 above.
    while data.length > limit
      if block_count == 1
        # Add extra MSODRAWINGGROUP block header.
        header = [mso_group, limit].pack('vv')
        block_count += 1
      else
        # Add normal CONTINUE header.
        header = [continue, limit].pack('vv')
      end

      tmp = data.dup[0, limit]
      data[0, limit] = ''
      append(header, tmp)
    end

    # Last CONTINUE block for remaining data. Case 2 and 3 above.
    header = [continue, data.length].pack('vv')
    append(header, data)

    # Turn the base class _add_continue() method back on.
    @ignore_continue = 0
  end

end