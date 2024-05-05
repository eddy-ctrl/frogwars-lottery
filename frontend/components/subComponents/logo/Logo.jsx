import Image from 'next/image'
import React from 'react'

export default function Logo() {
  return (
    <div className='flex items-center cursor-pointer'>
      <img className='w-14' src="/images/crystal.gif" alt='award image' />
        {/*  <img className='w-14' src="/images/dice-img.png" alt="award image" /> */}
        <p className='text-2xl px-3 font-customFont text-purple-500'>FrogWars Lottery</p>
    </div>
  )
}
